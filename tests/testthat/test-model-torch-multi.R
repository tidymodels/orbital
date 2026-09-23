torch_multi_model <- function() {
  torch::torch_manual_seed(1)
  list(
    trunk = torch::nn_sequential(torch::nn_linear(3, 4), torch::nn_relu()),
    heads = list(
      price = torch::nn_sequential(torch::nn_linear(4, 1)),
      category = torch::nn_sequential(torch::nn_linear(4, 2))
    )
  )
}

test_that("input_names is required", {
  skip_if_no_torch()

  x <- torch_multi_model()
  expect_snapshot(orbital(x), error = TRUE)
})

test_that("x must have exactly trunk and heads elements", {
  skip_if_no_torch()

  expect_snapshot(
    orbital(list(a = 1, b = 2), input_names = "x1"),
    error = TRUE
  )
})

test_that("trunk must be an nn_sequential", {
  skip_if_no_torch()

  x <- torch_multi_model()
  x$trunk <- "not a model"
  expect_snapshot(orbital(x, input_names = c("x1", "x2", "x3")), error = TRUE)
})

test_that("heads must be a non-empty named list of nn_sequential", {
  skip_if_no_torch()

  x <- torch_multi_model()
  x$heads <- list(torch::nn_sequential(torch::nn_linear(4, 1)))
  expect_snapshot(orbital(x, input_names = c("x1", "x2", "x3")), error = TRUE)

  x$heads <- list(price = "not a model")
  expect_snapshot(orbital(x, input_names = c("x1", "x2", "x3")), error = TRUE)
})

test_that("output_layer is not supported", {
  skip_if_no_torch()

  x <- torch_multi_model()
  expect_snapshot(
    orbital(x, input_names = c("x1", "x2", "x3"), output_layer = 1),
    error = TRUE
  )
})

test_that("mode/type/lvl must be named lists matching head names", {
  skip_if_no_torch()

  x <- torch_multi_model()
  expect_snapshot(
    orbital(
      x,
      input_names = c("x1", "x2", "x3"),
      mode = "regression"
    ),
    error = TRUE
  )

  expect_snapshot(
    orbital(
      x,
      input_names = c("x1", "x2", "x3"),
      mode = list(price = "regression", not_a_head = "classification")
    ),
    error = TRUE
  )
})

test_that("mixed regression + classification heads work end to end", {
  skip_if_no_torch()

  x <- torch_multi_model()
  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20), x3 = rnorm(20))

  ob <- orbital(
    x,
    input_names = c("x1", "x2", "x3"),
    mode = list(price = "regression", category = "classification"),
    lvl = list(category = c("standard", "luxury"))
  )
  preds <- predict(ob, data)

  expect_named(preds, c(".pred_price", ".pred_category_class"))

  input <- torch::torch_tensor(as.matrix(data))
  trunk_out <- x$trunk(input)
  price_out <- as.numeric(x$heads$price(trunk_out))
  category_out <- as.matrix(x$heads$category(trunk_out))
  category_class <- ifelse(
    category_out[, 1] >= category_out[, 2],
    "standard",
    "luxury"
  )

  expect_equal(preds$.pred_price, price_out, tolerance = 1e-5)
  expect_equal(preds$.pred_category_class, category_class)
})

test_that("mode is inferred and type/lvl default per head", {
  skip_if_no_torch()

  x <- torch_multi_model()
  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20), x3 = rnorm(20))

  ob <- orbital(x, input_names = c("x1", "x2", "x3"))
  preds <- predict(ob, data)

  expect_named(preds, c(".pred_price", ".pred_category_class"))
})

test_that("single output unit heads are binary classification", {
  skip_if_no_torch()

  torch::torch_manual_seed(1)
  x <- list(
    trunk = torch::nn_sequential(torch::nn_linear(2, 3), torch::nn_relu()),
    heads = list(
      a = torch::nn_sequential(torch::nn_linear(3, 1)),
      b = torch::nn_sequential(torch::nn_linear(3, 1))
    )
  )
  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20))

  ob <- orbital(
    x,
    input_names = c("x1", "x2"),
    mode = list(a = "classification", b = "classification")
  )
  preds <- predict(ob, data)

  expect_named(preds, c(".pred_a_class", ".pred_b_class"))
})

test_that("duckdb - multi-output network round-trips through real SQL", {
  skip_if_no_torch()
  skip_if_not_installed("duckdb")
  skip_if_not_installed("dbplyr")

  x <- torch_multi_model()
  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20), x3 = rnorm(20))

  ob <- orbital(
    x,
    input_names = c("x1", "x2", "x3"),
    mode = list(price = "regression", category = "classification"),
    lvl = list(category = c("standard", "luxury"))
  )
  r_preds <- predict(ob, data)

  con <- DBI::dbConnect(duckdb::duckdb())
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE))
  DBI::dbWriteTable(con, "nn_multi_data", data)

  db_preds <- dplyr::tbl(con, "nn_multi_data") |>
    dplyr::mutate(!!!orbital_inline(ob)) |>
    dplyr::select(dplyr::any_of(attr(ob, "pred_names"))) |>
    dplyr::collect()

  expect_equal(db_preds$.pred_price, r_preds$.pred_price, tolerance = 1e-5)
  expect_equal(db_preds$.pred_category_class, r_preds$.pred_category_class)
})
