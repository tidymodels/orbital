skip_if_no_keras <- function() {
  skip_if_not_installed("keras3")
  # The R package can be installed without a working TensorFlow/Python
  # backend (`keras3::install_keras()` never run); every call then errors
  # instead of the tests exercising anything.
  ok <- tryCatch(
    {
      keras3::keras_model_sequential(input_shape = 1)
      TRUE
    },
    error = function(cnd) FALSE
  )
  if (!ok) {
    skip("keras3's Python/TensorFlow backend is not available")
  }
}

keras_seq_model <- function(input_shape, ...) {
  keras3::set_random_seed(1)
  model <- keras3::keras_model_sequential(input_shape = input_shape)
  for (layer in list(...)) {
    model <- layer(model)
  }
  model
}

keras_predict <- function(model, data) {
  as.matrix(model$predict(as.matrix(data), verbose = 0))
}

# mtcars's predictors span wildly different scales (disp up to ~470, wt under
# 6); scaling avoids optimizer instability without changing anything the
# extraction code is exercising, mirroring `tests/testthat/test-model-brulee.R`.
scaled_mtcars <- within(mtcars, {
  disp <- scale(disp)[, 1]
  hp <- scale(hp)[, 1]
  wt <- scale(wt)[, 1]
})

test_that("input_names is required", {
  skip_if_no_keras()

  model <- keras_seq_model(2, \(m) keras3::layer_dense(m, units = 1))
  expect_snapshot(orbital(model), error = TRUE)
})

test_that("unsupported layers error", {
  skip_if_no_keras()

  model <- keras_seq_model(
    2,
    \(m) keras3::layer_dense(m, units = 2),
    \(m) keras3::layer_flatten(m)
  )
  expect_snapshot(
    orbital(model, input_names = c("x1", "x2")),
    error = TRUE
  )
})

test_that("unsupported activations error", {
  skip_if_no_keras()

  model <- keras_seq_model(
    2,
    \(m) keras3::layer_dense(m, units = 1, activation = "exponential")
  )
  expect_snapshot(
    orbital(model, input_names = c("x1", "x2")),
    error = TRUE
  )
})

test_that("input_names length is validated against the first layer", {
  skip_if_no_keras()

  model <- keras_seq_model(3, \(m) keras3::layer_dense(m, units = 1))
  expect_snapshot(
    orbital(model, input_names = c("x1", "x2")),
    error = TRUE
  )
})

test_that("regression network works, including 2+ hidden layers", {
  skip_if_no_keras()

  model <- keras_seq_model(
    3,
    \(m) keras3::layer_dense(m, units = 8, activation = "relu"),
    \(m) keras3::layer_dense(m, units = 6, activation = "tanh"),
    \(m) keras3::layer_dense(m, units = 1, activation = "linear")
  )
  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20), x3 = rnorm(20))

  ob <- orbital(model, input_names = c("x1", "x2", "x3"), mode = "regression")
  preds <- predict(ob, data)

  expect_named(preds, ".pred")
  expect_equal(
    preds$.pred,
    as.numeric(keras_predict(model, data)),
    tolerance = 1e-5
  )
})

test_that("mode is inferred from the final layer", {
  skip_if_no_keras()

  reg_model <- keras_seq_model(
    2,
    \(m) keras3::layer_dense(m, units = 4, activation = "relu"),
    \(m) keras3::layer_dense(m, units = 1, activation = "linear")
  )
  data <- data.frame(x1 = rnorm(10), x2 = rnorm(10))

  ob <- orbital(reg_model, input_names = c("x1", "x2"))
  expect_named(predict(ob, data), ".pred")

  class_model <- keras_seq_model(
    2,
    \(m) keras3::layer_dense(m, units = 4, activation = "relu"),
    \(m) keras3::layer_dense(m, units = 1, activation = "sigmoid")
  )
  ob2 <- orbital(
    class_model,
    input_names = c("x1", "x2"),
    type = c("class", "prob")
  )
  expect_named(
    predict(ob2, data),
    c(".pred_class", ".pred_class_0", ".pred_class_1")
  )
})

test_that("single-unit sigmoid binary classification works", {
  skip_if_no_keras()

  model <- keras_seq_model(
    3,
    \(m) keras3::layer_dense(m, units = 5, activation = "relu"),
    \(m) keras3::layer_dense(m, units = 1, activation = "sigmoid")
  )
  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20), x3 = rnorm(20))
  lvl <- c("no", "yes")

  ob <- orbital(
    model,
    input_names = c("x1", "x2", "x3"),
    type = c("class", "prob"),
    lvl = lvl
  )
  preds <- predict(ob, data)

  keras_probs <- as.numeric(keras_predict(model, data))
  expect_equal(preds$.pred_no, keras_probs, tolerance = 1e-5)
  expect_equal(preds$.pred_yes, 1 - keras_probs, tolerance = 1e-5)
  expect_identical(
    preds$.pred_class,
    ifelse(keras_probs > 0.5, "no", "yes")
  )
})

test_that("multiclass logits classification works, including 2+ hidden layers", {
  skip_if_no_keras()

  model <- keras_seq_model(
    4,
    \(m) keras3::layer_dense(m, units = 10, activation = "relu"),
    \(m) keras3::layer_dense(m, units = 8, activation = "elu"),
    \(m) keras3::layer_dense(m, units = 3, activation = "linear")
  )
  data <- data.frame(
    x1 = rnorm(20),
    x2 = rnorm(20),
    x3 = rnorm(20),
    x4 = rnorm(20)
  )
  lvl <- c("a", "b", "c")

  ob <- orbital(
    model,
    input_names = c("x1", "x2", "x3", "x4"),
    type = c("class", "prob"),
    lvl = lvl
  )
  preds <- predict(ob, data)

  logits <- keras_predict(model, data)
  probs <- exp(logits) / rowSums(exp(logits))
  colnames(probs) <- paste0(".pred_", lvl)

  expect_equal(
    as.matrix(preds[, paste0(".pred_", lvl)]),
    probs,
    ignore_attr = TRUE,
    tolerance = 1e-5
  )
  expect_identical(preds$.pred_class, lvl[apply(logits, 1, which.max)])
})

test_that("dropout is a no-op and does not error", {
  skip_if_no_keras()

  model <- keras_seq_model(
    2,
    \(m) keras3::layer_dense(m, units = 4, activation = "relu"),
    \(m) keras3::layer_dropout(m, rate = 0.5),
    \(m) keras3::layer_dense(m, units = 1, activation = "linear")
  )
  data <- data.frame(x1 = rnorm(10), x2 = rnorm(10))

  ob <- orbital(model, input_names = c("x1", "x2"), mode = "regression")
  preds <- predict(ob, data)

  expect_equal(
    preds$.pred,
    as.numeric(keras_predict(model, data)),
    tolerance = 1e-5
  )
})

test_that("output_layer exposes an intermediate layer's neuron columns", {
  skip_if_no_keras()

  model <- keras_seq_model(
    3,
    \(m) keras3::layer_dense(m, units = 4, activation = "relu"),
    \(m) keras3::layer_dense(m, units = 2, activation = "relu"),
    \(m) keras3::layer_dense(m, units = 1, activation = "linear")
  )
  data <- data.frame(x1 = rnorm(10), x2 = rnorm(10), x3 = rnorm(10))

  ob <- orbital(
    model,
    input_names = c("x1", "x2", "x3"),
    mode = "regression",
    output_layer = 2
  )
  preds <- predict(ob, data)

  expect_named(preds, c(".pred", "orbital_nn_L2_1", "orbital_nn_L2_2"))

  x <- as.matrix(data)
  hidden <- as.matrix(model$layers[[2]](model$layers[[1]](x)))

  expect_equal(
    as.matrix(preds[, c("orbital_nn_L2_1", "orbital_nn_L2_2")]),
    hidden,
    ignore_attr = TRUE,
    tolerance = 1e-5
  )
})

test_that("output_layer is validated against the number of hidden layers", {
  skip_if_no_keras()

  model <- keras_seq_model(
    2,
    \(m) keras3::layer_dense(m, units = 4, activation = "relu"),
    \(m) keras3::layer_dense(m, units = 1, activation = "linear")
  )
  expect_snapshot(
    orbital(
      model,
      input_names = c("x1", "x2"),
      mode = "regression",
      output_layer = 2L
    ),
    error = TRUE
  )
})

test_that("BatchNormalization works", {
  skip_if_no_keras()

  model <- keras_seq_model(
    3,
    \(m) keras3::layer_dense(m, units = 6),
    \(m) keras3::layer_batch_normalization(m),
    \(m) keras3::layer_activation(m, "relu"),
    \(m) keras3::layer_dense(m, units = 1)
  )
  x_train <- keras3::random_normal(c(50, 3))
  # Populate non-trivial moving statistics before predicting, so this test
  # actually exercises the affine transform rather than just its untrained
  # (moving mean 0, moving variance 1) defaults.
  invisible(model(x_train, training = TRUE))
  invisible(model(x_train, training = TRUE))

  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20), x3 = rnorm(20))
  ob <- orbital(model, input_names = c("x1", "x2", "x3"), mode = "regression")
  preds <- predict(ob, data)

  expect_equal(
    preds$.pred,
    as.numeric(keras_predict(model, data)),
    tolerance = 1e-5
  )
})

test_that("LayerNormalization works", {
  skip_if_no_keras()

  model <- keras_seq_model(
    3,
    \(m) keras3::layer_dense(m, units = 6),
    \(m) keras3::layer_layer_normalization(m),
    \(m) keras3::layer_activation(m, "tanh"),
    \(m) keras3::layer_dense(m, units = 1)
  )
  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20), x3 = rnorm(20))
  ob <- orbital(model, input_names = c("x1", "x2", "x3"), mode = "regression")
  preds <- predict(ob, data)

  expect_equal(
    preds$.pred,
    as.numeric(keras_predict(model, data)),
    tolerance = 1e-5
  )
})

test_that("normalization layer must come before the activation", {
  skip_if_no_keras()

  model <- keras_seq_model(
    2,
    \(m) keras3::layer_dense(m, units = 4, activation = "relu"),
    \(m) keras3::layer_batch_normalization(m),
    \(m) keras3::layer_dense(m, units = 1)
  )
  expect_snapshot(
    orbital(model, input_names = c("x1", "x2")),
    error = TRUE
  )
})

test_that("a Dense layer can only have one normalization layer", {
  skip_if_no_keras()

  model <- keras_seq_model(
    2,
    \(m) keras3::layer_dense(m, units = 4),
    \(m) keras3::layer_batch_normalization(m),
    \(m) keras3::layer_layer_normalization(m),
    \(m) keras3::layer_activation(m, "relu"),
    \(m) keras3::layer_dense(m, units = 1)
  )
  expect_snapshot(
    orbital(model, input_names = c("x1", "x2")),
    error = TRUE
  )
})

test_that("output_layer does not leak LayerNormalization's intermediate columns", {
  skip_if_no_keras()

  model <- keras_seq_model(
    3,
    \(m) keras3::layer_dense(m, units = 4),
    \(m) keras3::layer_layer_normalization(m),
    \(m) keras3::layer_activation(m, "relu"),
    \(m) keras3::layer_dense(m, units = 1)
  )
  data <- data.frame(x1 = rnorm(10), x2 = rnorm(10), x3 = rnorm(10))

  ob <- orbital(
    model,
    input_names = c("x1", "x2", "x3"),
    mode = "regression",
    output_layer = 1
  )
  preds <- predict(ob, data)

  expect_named(preds, c(".pred", paste0("orbital_nn_L1_", 1:4)))

  x <- as.matrix(data)
  hidden <- as.matrix(model$layers[[3]](model$layers[[2]](model$layers[[1]](
    x
  ))))
  expect_equal(
    as.matrix(preds[, paste0("orbital_nn_L1_", 1:4)]),
    hidden,
    ignore_attr = TRUE,
    tolerance = 1e-5
  )
})

skip_if_no_parsnip_keras <- function() {
  skip_if_no_keras()
  skip_if_not_installed("parsnip")
}

# Unlike brulee's engine, `parsnip::keras3_mlp()` only ever builds a single
# hidden `layer_dense()` from `hidden_units`, so `mlp(engine = "keras3")`
# cannot produce a 2+ hidden layer network; that case is only exercised
# through the bare entry point above.
keras_mlp_fit <- function(mode, formula, data, hidden_units = 6) {
  set.seed(1)
  keras3::set_random_seed(1)
  parsnip::fit(
    parsnip::set_mode(
      parsnip::set_engine(
        parsnip::mlp(
          epochs = 15,
          hidden_units = hidden_units,
          activation = "relu",
          learn_rate = 0.01
        ),
        "keras3"
      ),
      mode
    ),
    formula,
    data
  )
}

test_that("mlp(engine = keras3) regression works", {
  skip_if_no_parsnip_keras()

  fit <- keras_mlp_fit("regression", mpg ~ disp + hp + wt, scaled_mtcars)
  preds <- predict(orbital(fit), scaled_mtcars)

  expect_named(preds, ".pred")
  expect_equal(
    preds$.pred,
    as.numeric(keras_predict(fit$fit, scaled_mtcars[c("disp", "hp", "wt")])),
    tolerance = 1e-5
  )
})

test_that("mlp(engine = keras3) multiclass classification works", {
  skip_if_no_parsnip_keras()

  fit <- keras_mlp_fit("classification", Species ~ ., iris)
  preds <- predict(orbital(fit, type = c("class", "prob")), iris)

  logits <- keras_predict(fit$fit, iris[1:4])
  expect_equal(
    as.matrix(preds[, -1]),
    logits,
    ignore_attr = TRUE,
    tolerance = 1e-5
  )
  expect_identical(
    preds$.pred_class,
    fit$lvl[apply(logits, 1, which.max)]
  )
})

test_that("output_layer works through the parsnip mlp(engine = keras3) path", {
  skip_if_no_parsnip_keras()

  fit <- keras_mlp_fit(
    "regression",
    mpg ~ disp + hp + wt,
    scaled_mtcars,
    hidden_units = 6
  )
  preds <- predict(orbital(fit, output_layer = 1), scaled_mtcars)

  expect_named(preds, c(".pred", paste0("orbital_nn_L1_", 1:6)))

  x <- as.matrix(scaled_mtcars[c("disp", "hp", "wt")])
  hidden <- as.matrix(fit$fit$layers[[1]](x))

  expect_equal(
    as.matrix(preds[, paste0("orbital_nn_L1_", 1:6)]),
    hidden,
    ignore_attr = TRUE,
    tolerance = 1e-5
  )
})

test_that("duckdb - deep and wide networks round-trip through real SQL", {
  skip_if_no_keras()
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  deep_layers <- c(
    lapply(1:8, function(i) {
      \(m) keras3::layer_dense(m, units = 8, activation = "relu")
    }),
    list(\(m) keras3::layer_dense(m, units = 1, activation = "linear"))
  )
  deep_model <- do.call(keras_seq_model, c(list(4), deep_layers))
  wide_model <- keras_seq_model(
    4,
    \(m) keras3::layer_dense(m, units = 120, activation = "relu"),
    \(m) keras3::layer_dense(m, units = 1, activation = "linear")
  )
  norm_model <- keras_seq_model(
    4,
    \(m) keras3::layer_dense(m, units = 8),
    \(m) keras3::layer_batch_normalization(m),
    \(m) keras3::layer_activation(m, "relu"),
    \(m) keras3::layer_dense(m, units = 8),
    \(m) keras3::layer_layer_normalization(m),
    \(m) keras3::layer_activation(m, "tanh"),
    \(m) keras3::layer_dense(m, units = 1)
  )
  x_train <- keras3::random_normal(c(50, 4))
  invisible(norm_model(x_train, training = TRUE))
  invisible(norm_model(x_train, training = TRUE))
  data <- data.frame(
    x1 = rnorm(10),
    x2 = rnorm(10),
    x3 = rnorm(10),
    x4 = rnorm(10)
  )

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  data_tbl <- dplyr::copy_to(con, data, "keras_nn_data")

  for (model in list(deep = deep_model, wide = wide_model, norm = norm_model)) {
    ob <- orbital(model, input_names = c("x1", "x2", "x3", "x4"))
    res_sql <- dplyr::mutate(data_tbl, !!!orbital_inline(ob)) |>
      dplyr::collect()

    expect_equal(
      res_sql$.pred,
      as.numeric(keras_predict(model, data)),
      ignore_attr = TRUE,
      tolerance = 1e-5
    )
  }

  DBI::dbDisconnect(con)
})
