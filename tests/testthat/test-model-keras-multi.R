keras_multi_model <- function() {
  keras3::set_random_seed(1)
  inp <- keras3::keras_input(shape = 3L, name = "input")
  trunk <- inp |> keras3::layer_dense(4, activation = "relu", name = "trunk1")
  price <- trunk |> keras3::layer_dense(1, name = "price")
  category <- trunk |> keras3::layer_dense(2, name = "category")
  keras3::keras_model(
    inputs = inp,
    outputs = list(price = price, category = category)
  )
}

test_that("input_names is required", {
  skip_if_no_keras()

  x <- keras_multi_model()
  expect_snapshot(orbital(x), error = TRUE)
})

test_that("output_layer is not supported", {
  skip_if_no_keras()

  x <- keras_multi_model()
  expect_snapshot(
    orbital(x, input_names = c("x1", "x2", "x3"), output_layer = 1),
    error = TRUE
  )
})

test_that("a single-output functional model is rejected", {
  skip_if_no_keras()

  keras3::set_random_seed(1)
  inp <- keras3::keras_input(shape = 3L, name = "input")
  out <- inp |> keras3::layer_dense(1, name = "out")
  x <- keras3::keras_model(inputs = inp, outputs = out)

  expect_snapshot(
    orbital(x, input_names = c("x1", "x2", "x3")),
    error = TRUE
  )
})

test_that("multiple inputs are rejected", {
  skip_if_no_keras()

  keras3::set_random_seed(1)
  inp1 <- keras3::keras_input(shape = 2L, name = "input1")
  inp2 <- keras3::keras_input(shape = 1L, name = "input2")
  a <- inp1 |> keras3::layer_dense(1, name = "a")
  b <- inp2 |> keras3::layer_dense(1, name = "b")
  x <- keras3::keras_model(inputs = list(inp1, inp2), outputs = list(a, b))

  expect_snapshot(
    orbital(x, input_names = c("x1", "x2", "x3")),
    error = TRUE
  )
})

test_that("mode/type/lvl must be named lists matching head names", {
  skip_if_no_keras()

  x <- keras_multi_model()
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
  skip_if_no_keras()

  x <- keras_multi_model()
  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20), x3 = rnorm(20))

  ob <- orbital(
    x,
    input_names = c("x1", "x2", "x3"),
    mode = list(price = "regression", category = "classification"),
    lvl = list(category = c("standard", "luxury"))
  )
  preds <- predict(ob, data)

  expect_named(preds, c(".pred_price", ".pred_category_class"))

  pred_keras <- x$predict(as.matrix(data), verbose = 0)
  price_out <- as.numeric(pred_keras$price)
  category_out <- as.matrix(pred_keras$category)
  category_class <- ifelse(
    category_out[, 1] >= category_out[, 2],
    "standard",
    "luxury"
  )

  expect_equal(preds$.pred_price, price_out, tolerance = 1e-5)
  expect_equal(preds$.pred_category_class, category_class)
})

test_that("mode is inferred and type/lvl default per head", {
  skip_if_no_keras()

  x <- keras_multi_model()
  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20), x3 = rnorm(20))

  ob <- orbital(x, input_names = c("x1", "x2", "x3"))
  preds <- predict(ob, data)

  expect_named(preds, c(".pred_price", ".pred_category_class"))
})

test_that("heads with no shared trunk and their own hidden layer work", {
  skip_if_no_keras()

  keras3::set_random_seed(1)
  inp <- keras3::keras_input(shape = 2L, name = "input")
  a <- inp |>
    keras3::layer_dense(3, activation = "relu", name = "a1") |>
    keras3::layer_dense(1, name = "a")
  b <- inp |> keras3::layer_dense(1, name = "b")
  x <- keras3::keras_model(inputs = inp, outputs = list(a = a, b = b))

  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20))
  ob <- orbital(x, input_names = c("x1", "x2"))
  preds <- predict(ob, data)

  expect_named(preds, c(".pred_a", ".pred_b"))

  pred_keras <- x$predict(as.matrix(data), verbose = 0)
  expect_equal(preds$.pred_a, as.numeric(pred_keras$a), tolerance = 1e-5)
  expect_equal(preds$.pred_b, as.numeric(pred_keras$b), tolerance = 1e-5)
})

test_that("duckdb - multi-output network round-trips through real SQL", {
  skip_if_no_keras()
  skip_if_not_installed("duckdb")
  skip_if_not_installed("dbplyr")

  x <- keras_multi_model()
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
  DBI::dbWriteTable(con, "keras_nn_multi_data", data)

  db_preds <- dplyr::tbl(con, "keras_nn_multi_data") |>
    dplyr::mutate(!!!orbital_inline(ob)) |>
    dplyr::select(dplyr::any_of(attr(ob, "pred_names"))) |>
    dplyr::collect()

  expect_equal(db_preds$.pred_price, r_preds$.pred_price, tolerance = 1e-5)
  expect_equal(db_preds$.pred_category_class, r_preds$.pred_category_class)
})
