skip_if_no_brulee <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("brulee")
  skip_if_not_installed("torch")
  # See `tests/testthat/test-model-torch.R`: the R package can be installed
  # without LibTorch itself.
  if (!torch::torch_is_installed()) {
    skip("libtorch is not installed")
  }
}

# mtcars's predictors span wildly different scales (disp up to ~470, wt under
# 6), which combined with a few unscaled ReLU layers is enough to overflow
# LBFGS (brulee's default optimizer) during training; scaling avoids that
# without changing anything the extraction code is exercising.
scaled_mtcars <- within(mtcars, {
  disp <- scale(disp)[, 1]
  hp <- scale(hp)[, 1]
  wt <- scale(wt)[, 1]
})

brulee_mlp_fit <- function(mode, formula, data, hidden_units = c(6, 5)) {
  set.seed(1)
  torch::torch_manual_seed(1)
  parsnip::fit(
    parsnip::set_mode(
      parsnip::set_engine(
        parsnip::mlp(
          epochs = 15,
          hidden_units = hidden_units,
          activation = "relu",
          learn_rate = 0.01
        ),
        "brulee"
      ),
      mode
    ),
    formula,
    data
  )
}

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
