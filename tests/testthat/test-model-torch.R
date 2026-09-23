skip_if_no_torch <- function() {
  skip_if_not_installed("torch")
  # The R package can be installed without LibTorch itself (`install_torch()`
  # never run), which is the state most CI runners are in; every torch call
  # then errors with "Lantern is not loaded" instead of the tests exercising
  # anything.
  if (!torch::torch_is_installed()) {
    skip("libtorch is not installed")
  }
}

torch_seq_model <- function(...) {
  torch::torch_manual_seed(1)
  torch::nn_sequential(...)
}

torch_predict <- function(model, data) {
  x <- torch::torch_tensor(as.matrix(data))
  as.matrix(model(x))
}

test_that("input_names is required", {
  skip_if_no_torch()

  model <- torch_seq_model(torch::nn_linear(2, 1))
  expect_snapshot(orbital(model), error = TRUE)
})

test_that("unsupported modules error", {
  skip_if_no_torch()

  model <- torch_seq_model(torch::nn_linear(2, 2), torch::nn_softmin(dim = 1))
  expect_snapshot(
    orbital(model, input_names = c("x1", "x2")),
    error = TRUE
  )
})

test_that("input_names length is validated against the first layer", {
  skip_if_no_torch()

  model <- torch_seq_model(torch::nn_linear(3, 1))
  expect_snapshot(
    orbital(model, input_names = c("x1", "x2")),
    error = TRUE
  )
})

test_that("lvl length is validated against the network's output width", {
  skip_if_no_torch()

  bin_model <- torch_seq_model(torch::nn_linear(2, 1))
  expect_snapshot(
    orbital(
      bin_model,
      input_names = c("x1", "x2"),
      mode = "classification",
      lvl = "only_one"
    ),
    error = TRUE
  )

  multi_model <- torch_seq_model(torch::nn_linear(2, 3))
  expect_snapshot(
    orbital(
      multi_model,
      input_names = c("x1", "x2"),
      mode = "classification",
      lvl = c("a", "b")
    ),
    error = TRUE
  )
})

test_that("orbital.nn_sequential validates type against mode", {
  skip_if_no_torch()

  model <- torch_seq_model(torch::nn_linear(2, 1))
  expect_snapshot(
    orbital(
      model,
      input_names = c("x1", "x2"),
      mode = "classification",
      type = "numeric"
    ),
    error = TRUE
  )
})

test_that("nn_linear(bias = FALSE) is treated as an all-zero bias", {
  skip_if_no_torch()

  model <- torch_seq_model(torch::nn_linear(3, 1, bias = FALSE))
  data <- data.frame(x1 = rnorm(10), x2 = rnorm(10), x3 = rnorm(10))

  ob <- orbital(
    model,
    input_names = c("x1", "x2", "x3"),
    mode = "regression"
  )
  preds <- predict(ob, data)

  expect_equal(
    preds$.pred,
    as.numeric(torch_predict(model, data)),
    tolerance = 1e-5
  )
})

test_that("nn_softmax is only supported as the final layer's activation", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(2, 4),
    torch::nn_softmax(dim = 2),
    torch::nn_linear(4, 1)
  )
  expect_snapshot(
    orbital(model, input_names = c("x1", "x2")),
    error = TRUE
  )
})

test_that("nn_softmax over a non-class dimension errors", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(2, 3),
    torch::nn_softmax(dim = 1)
  )
  expect_snapshot(
    orbital(model, input_names = c("x1", "x2")),
    error = TRUE
  )
})

test_that("regression network works, including 2+ hidden layers", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(3, 8),
    torch::nn_relu(),
    torch::nn_linear(8, 6),
    torch::nn_tanh(),
    torch::nn_linear(6, 1)
  )
  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20), x3 = rnorm(20))

  ob <- orbital(model, input_names = c("x1", "x2", "x3"), mode = "regression")
  preds <- predict(ob, data)

  expect_named(preds, ".pred")
  expect_equal(
    preds$.pred,
    as.numeric(torch_predict(model, data)),
    tolerance = 1e-5
  )
})

test_that("mode is inferred from the final module", {
  skip_if_no_torch()

  reg_model <- torch_seq_model(
    torch::nn_linear(2, 4),
    torch::nn_relu(),
    torch::nn_linear(4, 1)
  )
  data <- data.frame(x1 = rnorm(10), x2 = rnorm(10))

  ob <- orbital(reg_model, input_names = c("x1", "x2"))
  expect_named(predict(ob, data), ".pred")

  class_model <- torch_seq_model(
    torch::nn_linear(2, 4),
    torch::nn_relu(),
    torch::nn_linear(4, 1),
    torch::nn_sigmoid()
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
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(3, 5),
    torch::nn_relu(),
    torch::nn_linear(5, 1),
    torch::nn_sigmoid()
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

  # a single output unit is treated as P(first level), i.e. P("no")
  torch_probs <- as.numeric(torch_predict(model, data))
  expect_equal(preds$.pred_no, torch_probs, tolerance = 1e-5)
  expect_equal(preds$.pred_yes, 1 - torch_probs, tolerance = 1e-5)
  expect_identical(
    preds$.pred_class,
    ifelse(torch_probs > 0.5, "no", "yes")
  )
})

test_that("multiclass logits classification works, including 2+ hidden layers", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(4, 10),
    torch::nn_relu(),
    torch::nn_linear(10, 8),
    torch::nn_elu(),
    torch::nn_linear(8, 3)
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

  logits <- torch_predict(model, data)
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
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(2, 4),
    torch::nn_relu(),
    torch::nn_dropout(0.5),
    torch::nn_linear(4, 1)
  )
  model$eval()
  data <- data.frame(x1 = rnorm(10), x2 = rnorm(10))

  ob <- orbital(model, input_names = c("x1", "x2"), mode = "regression")
  preds <- predict(ob, data)

  expect_equal(
    preds$.pred,
    as.numeric(torch_predict(model, data)),
    tolerance = 1e-5
  )
})

test_that("nn_batch_norm1d works", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(3, 6),
    torch::nn_batch_norm1d(6),
    torch::nn_relu(),
    torch::nn_linear(6, 1)
  )
  # Populate non-trivial running statistics before switching to eval mode, so
  # this test actually exercises the affine transform rather than just its
  # untrained (mean 0, var 1) defaults.
  model$train(TRUE)
  invisible(model(torch::torch_randn(50, 3)))
  model$train(FALSE)

  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20), x3 = rnorm(20))
  ob <- orbital(model, input_names = c("x1", "x2", "x3"), mode = "regression")
  preds <- predict(ob, data)

  expect_equal(
    preds$.pred,
    as.numeric(torch_predict(model, data)),
    tolerance = 1e-5
  )
})

test_that("nn_layer_norm works", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(3, 6),
    torch::nn_layer_norm(6),
    torch::nn_tanh(),
    torch::nn_linear(6, 1)
  )
  data <- data.frame(x1 = rnorm(20), x2 = rnorm(20), x3 = rnorm(20))
  ob <- orbital(model, input_names = c("x1", "x2", "x3"), mode = "regression")
  preds <- predict(ob, data)

  expect_equal(
    preds$.pred,
    as.numeric(torch_predict(model, data)),
    tolerance = 1e-5
  )
})

test_that("normalization module must come before the activation", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(2, 4),
    torch::nn_relu(),
    torch::nn_batch_norm1d(4),
    torch::nn_linear(4, 1)
  )
  expect_snapshot(
    orbital(model, input_names = c("x1", "x2")),
    error = TRUE
  )
})

test_that("a linear layer can only have one normalization module", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(2, 4),
    torch::nn_batch_norm1d(4),
    torch::nn_layer_norm(4),
    torch::nn_relu(),
    torch::nn_linear(4, 1)
  )
  expect_snapshot(
    orbital(model, input_names = c("x1", "x2")),
    error = TRUE
  )
})

test_that("nn_batch_norm1d with track_running_stats = FALSE errors", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(2, 4),
    torch::nn_batch_norm1d(4, track_running_stats = FALSE),
    torch::nn_relu(),
    torch::nn_linear(4, 1)
  )
  expect_snapshot(
    orbital(model, input_names = c("x1", "x2")),
    error = TRUE
  )
})

test_that("nn_layer_norm normalizing over a mismatched width errors", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(2, 4),
    torch::nn_layer_norm(2),
    torch::nn_relu(),
    torch::nn_linear(4, 1)
  )
  expect_snapshot(
    orbital(model, input_names = c("x1", "x2")),
    error = TRUE
  )
})

test_that("output_layer does not leak nn_layer_norm's intermediate columns", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(3, 4),
    torch::nn_layer_norm(4),
    torch::nn_relu(),
    torch::nn_linear(4, 1)
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

  x <- torch::torch_tensor(as.matrix(data))
  hidden <- as.matrix(model[[3]](model[[2]](model[[1]](x))))
  expect_equal(
    as.matrix(preds[, paste0("orbital_nn_L1_", 1:4)]),
    hidden,
    ignore_attr = TRUE,
    tolerance = 1e-5
  )
})

test_that("wide network expression size stays roughly linear, not exponential", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(5, 60),
    torch::nn_relu(),
    torch::nn_linear(60, 1)
  )

  ob <- orbital(model, input_names = paste0("x", 1:5), mode = "regression")
  sql_size <- nchar(paste(unclass(ob), collapse = ""))

  expect_lt(sql_size, 1e5)
})

test_that("output_layer exposes an intermediate layer's neuron columns", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(3, 4),
    torch::nn_relu(),
    torch::nn_linear(4, 2),
    torch::nn_relu(),
    torch::nn_linear(2, 1)
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

  x <- torch::torch_tensor(as.matrix(data))
  hidden <- as.matrix(model[[4]](model[[3]](model[[2]](model[[1]](x)))))
  expect_equal(
    as.matrix(preds[, c("orbital_nn_L2_1", "orbital_nn_L2_2")]),
    hidden,
    ignore_attr = TRUE,
    tolerance = 1e-5
  )
})

test_that("output_layer is validated against the number of hidden layers", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(2, 4),
    torch::nn_relu(),
    torch::nn_linear(4, 1)
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

test_that("duckdb - deep and wide networks round-trip through real SQL", {
  skip_if_no_torch()
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  deep_model <- torch_seq_model(
    torch::nn_linear(4, 8),
    torch::nn_relu(),
    torch::nn_linear(8, 8),
    torch::nn_relu(),
    torch::nn_linear(8, 8),
    torch::nn_relu(),
    torch::nn_linear(8, 8),
    torch::nn_relu(),
    torch::nn_linear(8, 8),
    torch::nn_relu(),
    torch::nn_linear(8, 8),
    torch::nn_relu(),
    torch::nn_linear(8, 8),
    torch::nn_relu(),
    torch::nn_linear(8, 8),
    torch::nn_relu(),
    torch::nn_linear(8, 1)
  )
  wide_model <- torch_seq_model(
    torch::nn_linear(4, 120),
    torch::nn_relu(),
    torch::nn_linear(120, 1)
  )
  norm_model <- torch_seq_model(
    torch::nn_linear(4, 8),
    torch::nn_batch_norm1d(8),
    torch::nn_relu(),
    torch::nn_linear(8, 8),
    torch::nn_layer_norm(8),
    torch::nn_tanh(),
    torch::nn_linear(8, 1)
  )
  norm_model$train(TRUE)
  invisible(norm_model(torch::torch_randn(50, 4)))
  norm_model$train(FALSE)
  data <- data.frame(
    x1 = rnorm(10),
    x2 = rnorm(10),
    x3 = rnorm(10),
    x4 = rnorm(10)
  )

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  data_tbl <- dplyr::copy_to(con, data, "nn_data")

  for (model in list(deep = deep_model, wide = wide_model, norm = norm_model)) {
    ob <- orbital(model, input_names = c("x1", "x2", "x3", "x4"))
    res_sql <- dplyr::mutate(data_tbl, !!!orbital_inline(ob)) |>
      dplyr::collect()

    expect_equal(
      res_sql$.pred,
      as.numeric(torch_predict(model, data)),
      ignore_attr = TRUE,
      tolerance = 1e-5
    )
  }

  DBI::dbDisconnect(con)
})
