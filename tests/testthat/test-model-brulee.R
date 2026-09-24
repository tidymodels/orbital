test_that("brulee's revive/epoch-indexing internals have the expected shape", {
  skip_if_no_brulee()

  fit <- brulee_mlp_fit("regression", mpg ~ disp + hp, mtcars, hidden_units = 4)
  obj <- fit$fit

  expect_named(
    obj,
    c(
      "model_obj",
      "estimates",
      "best_epoch",
      "loss",
      "dims",
      "y_stats",
      "output_type",
      "parameters",
      "device",
      "blueprint"
    )
  )
  expect_equal(
    names(obj$estimates[[1]]),
    c(
      "model.0.weight",
      "model.0.bias",
      "model.2.weight",
      "model.2.bias"
    )
  )

  module <- brulee_revive_mlp(obj)
  expect_s3_class(module, "nn_module")
  expect_named(module$model$children, c("0", "1", "2"))
})

test_that("mlp(engine = brulee) regression works, including 2+ hidden layers", {
  skip_if_no_brulee()

  fit <- brulee_mlp_fit("regression", mpg ~ disp + hp + wt, scaled_mtcars)
  preds <- predict(orbital(fit), scaled_mtcars)

  expect_named(preds, ".pred")
  expect_equal(
    preds$.pred,
    predict(fit, scaled_mtcars)$.pred,
    ignore_attr = TRUE,
    tolerance = 1e-5
  )
})

test_that("mlp(engine = brulee) multiclass classification works", {
  skip_if_no_brulee()

  fit <- brulee_mlp_fit("classification", Species ~ ., iris)
  preds <- predict(orbital(fit, type = c("class", "prob")), iris)

  expect_equal(
    as.matrix(preds[, -1]),
    as.matrix(predict(fit, iris, type = "prob")),
    ignore_attr = TRUE,
    tolerance = 1e-5
  )
  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, iris)$.pred_class)
  )
})

test_that("mlp(engine = brulee) binary classification works", {
  skip_if_no_brulee()

  data <- scaled_mtcars
  data$vs <- factor(data$vs)

  fit <- brulee_mlp_fit("classification", vs ~ disp + hp + wt, data)
  preds <- predict(orbital(fit, type = c("class", "prob")), data)

  expect_named(preds, c(".pred_class", ".pred_0", ".pred_1"))
  expect_equal(
    as.matrix(preds[, -1]),
    as.matrix(predict(fit, data, type = "prob")),
    ignore_attr = TRUE,
    tolerance = 1e-5
  )
  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, data)$.pred_class)
  )
})

test_that("output_layer exposes an intermediate layer's neuron columns", {
  skip_if_no_brulee()

  fit <- brulee_mlp_fit("regression", mpg ~ disp + hp + wt, scaled_mtcars)
  preds <- predict(orbital(fit, output_layer = 1), scaled_mtcars)

  expect_named(
    preds,
    c(".pred", paste0("orbital_nn_L1_", 1:6))
  )

  module <- brulee_revive_mlp(fit$fit)
  x <- torch::torch_tensor(
    as.matrix(scaled_mtcars[c("disp", "hp", "wt")]),
    dtype = torch::torch_float()
  )
  hidden <- as.matrix(module$model[[2]](module$model[[1]](x)))

  expect_equal(
    as.matrix(preds[, paste0("orbital_nn_L1_", 1:6)]),
    hidden,
    ignore_attr = TRUE,
    tolerance = 1e-5
  )
})

test_that("output_layer is only supported for brulee_mlp models", {
  skip_if_not_installed("parsnip")

  fit <- parsnip::fit(parsnip::linear_reg(), mpg ~ disp, mtcars)
  expect_snapshot(orbital(fit, output_layer = 1), error = TRUE)
})

test_that("duckdb - brulee mlp round-trips through real SQL", {
  skip_if_no_brulee()
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  fit <- brulee_mlp_fit("regression", mpg ~ disp + hp + wt, scaled_mtcars)
  ob <- orbital(fit)

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  data_tbl <- dplyr::copy_to(con, scaled_mtcars, "brulee_data")

  res_sql <- dplyr::mutate(data_tbl, !!!orbital_inline(ob)) |>
    dplyr::collect()

  expect_equal(
    res_sql$.pred,
    predict(fit, scaled_mtcars)$.pred,
    ignore_attr = TRUE,
    tolerance = 1e-5
  )

  DBI::dbDisconnect(con)
})

test_that("mlp(engine = brulee) dropout is a no-op and does not error", {
  skip_if_no_brulee()

  set.seed(1)
  torch::torch_manual_seed(1)
  fit <- parsnip::fit(
    parsnip::set_mode(
      parsnip::set_engine(
        parsnip::mlp(
          epochs = 15,
          hidden_units = 4,
          dropout = 0.3,
          learn_rate = 0.01
        ),
        "brulee"
      ),
      "regression"
    ),
    mpg ~ disp + hp,
    mtcars
  )
  preds <- predict(orbital(fit), mtcars)

  expect_equal(
    preds$.pred,
    predict(fit, mtcars)$.pred,
    ignore_attr = TRUE,
    tolerance = 1e-5
  )
})
