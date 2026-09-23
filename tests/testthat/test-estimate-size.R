test_that("estimate_orbital_size works for xgboost regression", {
  skip_if_not_installed("xgboost")

  x <- as.matrix(mtcars[, -1])
  y <- mtcars[, 1]
  model <- xgboost::xgboost(
    x = x,
    y = y,
    nrounds = 10,
    max_depth = 3,
    verbosity = 0
  )

  est <- estimate_orbital_size(model)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

test_that("estimate_orbital_size scales with tree count", {
  skip_if_not_installed("xgboost")

  x <- as.matrix(mtcars[, -1])
  y <- mtcars[, 1]

  model_small <- xgboost::xgboost(
    x = x,
    y = y,
    nrounds = 10,
    max_depth = 3,
    verbosity = 0
  )
  model_large <- xgboost::xgboost(
    x = x,
    y = y,
    nrounds = 50,
    max_depth = 3,
    verbosity = 0
  )

  est_small <- estimate_orbital_size(model_small)
  est_large <- estimate_orbital_size(model_large)

  expect_gt(est_large, est_small)
  # Should scale roughly linearly with tree count
  ratio <- est_large / est_small
  expect_gt(ratio, 3)
  expect_lt(ratio, 7)
})

test_that("estimate_orbital_size scales with tree depth", {
  skip_if_not_installed("xgboost")

  set.seed(42)
  n <- 500
  x <- matrix(rnorm(n * 5), ncol = 5)
  y <- rowSums(x) + rnorm(n)

  model_shallow <- xgboost::xgboost(
    x = x,
    y = y,
    nrounds = 20,
    max_depth = 2,
    verbosity = 0
  )
  model_deep <- xgboost::xgboost(
    x = x,
    y = y,
    nrounds = 20,
    max_depth = 6,
    verbosity = 0
  )

  est_shallow <- estimate_orbital_size(model_shallow)
  est_deep <- estimate_orbital_size(model_deep)

  expect_gt(est_deep, est_shallow)
})

test_that("estimate_orbital_size errors for unsupported types", {
  expect_snapshot(error = TRUE, estimate_orbital_size(Sys.time()))
})

# lightgbm tests
test_that("estimate_orbital_size works for lightgbm", {
  skip_if_not_installed("lightgbm")

  set.seed(42)
  n <- 500
  x <- matrix(rnorm(n * 5), ncol = 5)
  colnames(x) <- paste0("var_", 1:5)
  y <- rowSums(x) + rnorm(n)

  dtrain <- lightgbm::lgb.Dataset(x, label = y)
  params <- list(objective = "regression", num_leaves = 15, verbose = -1)
  model <- lightgbm::lgb.train(params, dtrain, nrounds = 10)

  est <- estimate_orbital_size(model)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

test_that("estimate_orbital_size scales with tree count for lightgbm", {
  skip_if_not_installed("lightgbm")

  set.seed(42)
  n <- 500
  x <- matrix(rnorm(n * 5), ncol = 5)
  colnames(x) <- paste0("var_", 1:5)
  y <- rowSums(x) + rnorm(n)

  dtrain <- lightgbm::lgb.Dataset(x, label = y)
  params <- list(objective = "regression", num_leaves = 15, verbose = -1)

  model_small <- lightgbm::lgb.train(params, dtrain, nrounds = 10)
  model_large <- lightgbm::lgb.train(params, dtrain, nrounds = 50)

  est_small <- estimate_orbital_size(model_small)
  est_large <- estimate_orbital_size(model_large)

  expect_gt(est_large, est_small)
})

# ranger tests
test_that("estimate_orbital_size works for ranger", {
  skip_if_not_installed("ranger")

  model <- ranger::ranger(mpg ~ ., data = mtcars, num.trees = 10, max.depth = 4)

  est <- estimate_orbital_size(model)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

test_that("estimate_orbital_size scales with tree count for ranger", {
  skip_if_not_installed("ranger")

  model_small <- ranger::ranger(
    mpg ~ .,
    data = mtcars,
    num.trees = 10,
    max.depth = 4
  )
  model_large <- ranger::ranger(
    mpg ~ .,
    data = mtcars,
    num.trees = 50,
    max.depth = 4
  )

  est_small <- estimate_orbital_size(model_small)
  est_large <- estimate_orbital_size(model_large)

  expect_gt(est_large, est_small)
})

# randomForest tests
test_that("estimate_orbital_size works for randomForest", {
  skip_if_not_installed("randomForest")

  model <- randomForest::randomForest(mpg ~ ., data = mtcars, ntree = 10)

  est <- estimate_orbital_size(model)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

test_that("estimate_orbital_size scales with tree count for randomForest", {
  skip_if_not_installed("randomForest")

  model_small <- randomForest::randomForest(mpg ~ ., data = mtcars, ntree = 10)
  model_large <- randomForest::randomForest(mpg ~ ., data = mtcars, ntree = 50)

  est_small <- estimate_orbital_size(model_small)
  est_large <- estimate_orbital_size(model_large)

  expect_gt(est_large, est_small)
})

# rpart tests
test_that("estimate_orbital_size works for rpart", {
  model <- rpart::rpart(mpg ~ ., data = mtcars)

  est <- estimate_orbital_size(model)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

test_that("estimate_orbital_size scales with tree complexity for rpart", {
  model_simple <- rpart::rpart(mpg ~ ., data = mtcars, maxdepth = 2)
  model_complex <- rpart::rpart(
    mpg ~ .,
    data = mtcars,
    maxdepth = 10,
    minsplit = 2
  )

  est_simple <- estimate_orbital_size(model_simple)
  est_complex <- estimate_orbital_size(model_complex)

  expect_gt(est_complex, est_simple)
})

# partykit tests
test_that("estimate_orbital_size works for constparty", {
  skip_if_not_installed("partykit")

  model <- partykit::ctree(mpg ~ ., data = mtcars)

  est <- estimate_orbital_size(model)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

# catboost tests
test_that("estimate_orbital_size works for catboost", {
  skip_if_not_installed("bonsai")
  skip_if_not_installed("catboost")

  bt_spec <- parsnip::boost_tree(trees = 10, tree_depth = 3) |>
    parsnip::set_engine("catboost", verbose = 0) |>
    parsnip::set_mode("regression")

  bt_fit <- parsnip::fit(bt_spec, mpg ~ disp + hp + wt, data = mtcars)

  est <- estimate_orbital_size(bt_fit$fit)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

# glm tests
test_that("estimate_orbital_size works for glm", {
  model <- glm(mpg ~ ., data = mtcars)

  est <- estimate_orbital_size(model)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

test_that("estimate_orbital_size works for lm", {
  model <- lm(mpg ~ ., data = mtcars)

  est <- estimate_orbital_size(model)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

test_that("estimate_orbital_size scales with predictor count for glm", {
  model_small <- glm(mpg ~ cyl + hp, data = mtcars)
  model_large <- glm(mpg ~ ., data = mtcars)

  est_small <- estimate_orbital_size(model_small)
  est_large <- estimate_orbital_size(model_large)

  expect_gt(est_large, est_small)
})

# glmnet tests
test_that("estimate_orbital_size works for glmnet", {
  skip_if_not_installed("glmnet")

  x <- as.matrix(mtcars[, -1])
  y <- mtcars[, 1]
  model <- glmnet::glmnet(x, y, lambda = 0.1)

  est <- estimate_orbital_size(model)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

test_that("estimate_orbital_size errors for glmnet with multiple lambdas", {
  skip_if_not_installed("glmnet")

  x <- as.matrix(mtcars[, -1])
  y <- mtcars[, 1]
  model <- glmnet::glmnet(x, y)

  expect_snapshot(error = TRUE, estimate_orbital_size(model))
})

# earth tests
test_that("estimate_orbital_size works for earth", {
  skip_if_not_installed("earth")

  model <- earth::earth(mpg ~ ., data = mtcars)

  est <- estimate_orbital_size(model)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

test_that("estimate_orbital_size scales with tree count for catboost", {
  skip_if_not_installed("bonsai")
  skip_if_not_installed("catboost")

  bt_spec_small <- parsnip::boost_tree(trees = 10, tree_depth = 3) |>
    parsnip::set_engine("catboost", verbose = 0) |>
    parsnip::set_mode("regression")

  bt_spec_large <- parsnip::boost_tree(trees = 50, tree_depth = 3) |>
    parsnip::set_engine("catboost", verbose = 0) |>
    parsnip::set_mode("regression")

  model_small <- parsnip::fit(
    bt_spec_small,
    mpg ~ disp + hp + wt,
    data = mtcars
  )
  model_large <- parsnip::fit(
    bt_spec_large,
    mpg ~ disp + hp + wt,
    data = mtcars
  )

  est_small <- estimate_orbital_size(model_small$fit)
  est_large <- estimate_orbital_size(model_large$fit)

  expect_gt(est_large, est_small)
})

# Recipe tests
test_that("estimate_orbital_size works for recipe", {
  skip_if_not_installed("recipes")

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_normalize(recipes::all_numeric_predictors()) |>
    recipes::prep()

  est <- estimate_orbital_size(rec)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

test_that("estimate_orbital_size works for recipe with dummy", {
  skip_if_not_installed("recipes")

  mtcars2 <- mtcars
  mtcars2$cyl <- factor(mtcars2$cyl)

  rec <- recipes::recipe(mpg ~ ., data = mtcars2) |>
    recipes::step_dummy(recipes::all_nominal_predictors()) |>
    recipes::prep()

  est <- estimate_orbital_size(rec)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

test_that("estimate_orbital_size scales with recipe complexity", {
  skip_if_not_installed("recipes")

  rec_simple <- recipes::recipe(mpg ~ disp + hp, data = mtcars) |>
    recipes::step_normalize(recipes::all_numeric_predictors()) |>
    recipes::prep()

  rec_complex <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_normalize(recipes::all_numeric_predictors()) |>
    recipes::prep()

  est_simple <- estimate_orbital_size(rec_simple)
  est_complex <- estimate_orbital_size(rec_complex)

  expect_gt(est_complex, est_simple)
})

# Workflow tests
test_that("estimate_orbital_size works for workflow", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("workflows")
  skip_if_not_installed("parsnip")

  wf <- workflows::workflow() |>
    workflows::add_recipe(
      recipes::recipe(mpg ~ ., data = mtcars) |>
        recipes::step_normalize(recipes::all_numeric_predictors())
    ) |>
    workflows::add_model(parsnip::linear_reg()) |>
    parsnip::fit(mtcars)

  est <- estimate_orbital_size(wf)

  expect_type(est, "integer")
  expect_gt(est, 0)
})

test_that("estimate_orbital_size for workflow combines recipe and model", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("workflows")
  skip_if_not_installed("parsnip")

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_normalize(recipes::all_numeric_predictors())

  wf <- workflows::workflow() |>
    workflows::add_recipe(rec) |>
    workflows::add_model(parsnip::linear_reg()) |>
    parsnip::fit(mtcars)

  wf_est <- estimate_orbital_size(wf)

  # Estimate should be in reasonable range of actual size
  orb <- orbital(wf)
  actual <- sum(nchar(orb))

  # Within 50% is acceptable for estimation
  expect_gt(wf_est, actual * 0.5)
  expect_lt(wf_est, actual * 1.5)
})

test_that("estimate_orbital_size refuses a workflow whose model has no estimate", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("workflows")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("nnet")

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_normalize(recipes::all_numeric_predictors())

  wf <- workflows::workflow() |>
    workflows::add_recipe(rec) |>
    workflows::add_model(
      parsnip::mlp(mode = "regression", engine = "nnet", epochs = 10)
    ) |>
    parsnip::fit(mtcars)

  expect_snapshot(error = TRUE, estimate_orbital_size(wf))
})

test_that("estimate_orbital_size refuses a model it has no estimate for", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("nnet")

  fit <- parsnip::fit(
    parsnip::mlp(mode = "regression", engine = "nnet", epochs = 10),
    mpg ~ .,
    mtcars
  )

  expect_snapshot(error = TRUE, estimate_orbital_size(fit$fit))
})

test_that("estimate_orbital_size works for bare nn_sequential", {
  skip_if_not_installed("torch")
  if (!torch::torch_is_installed()) {
    skip("libtorch is not installed")
  }

  torch::torch_manual_seed(1)
  model <- torch::nn_sequential(
    torch::nn_linear(3, 8),
    torch::nn_relu(),
    torch::nn_linear(8, 1)
  )

  est <- estimate_orbital_size(model, input_names = c("x1", "x2", "x3"))
  actual <- sum(nchar(orbital(model, input_names = c("x1", "x2", "x3"))))

  expect_type(est, "integer")
  expect_equal(est, actual, tolerance = 0.1)
})

test_that("estimate_orbital_size requires input_names for nn_sequential", {
  skip_if_not_installed("torch")
  if (!torch::torch_is_installed()) {
    skip("libtorch is not installed")
  }

  torch::torch_manual_seed(1)
  model <- torch::nn_sequential(torch::nn_linear(3, 1))
  expect_snapshot(error = TRUE, estimate_orbital_size(model))
})

test_that("estimate_orbital_size scales with network depth/width for nn_sequential", {
  skip_if_not_installed("torch")
  if (!torch::torch_is_installed()) {
    skip("libtorch is not installed")
  }

  torch::torch_manual_seed(1)
  small <- torch::nn_sequential(torch::nn_linear(3, 4), torch::nn_linear(4, 1))
  large <- torch::nn_sequential(
    torch::nn_linear(3, 40),
    torch::nn_linear(40, 1)
  )

  est_small <- estimate_orbital_size(small, input_names = c("x1", "x2", "x3"))
  est_large <- estimate_orbital_size(large, input_names = c("x1", "x2", "x3"))

  expect_gt(est_large, est_small)
})

test_that("estimate_orbital_size works for brulee_mlp", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("brulee")
  skip_if_not_installed("torch")
  if (!torch::torch_is_installed()) {
    skip("libtorch is not installed")
  }

  set.seed(1)
  torch::torch_manual_seed(1)
  fit <- parsnip::fit(
    parsnip::set_mode(
      parsnip::set_engine(
        parsnip::mlp(epochs = 5, hidden_units = 4),
        "brulee"
      ),
      "regression"
    ),
    mpg ~ disp + hp,
    mtcars
  )

  est <- estimate_orbital_size(fit$fit)
  actual <- sum(nchar(orbital(fit)))

  expect_type(est, "integer")
  expect_equal(est, actual, tolerance = 0.1)
})

skip_if_no_keras_estimate <- function() {
  skip_if_not_installed("keras3")
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

test_that("estimate_orbital_size works for bare keras3 Sequential", {
  skip_if_no_keras_estimate()

  keras3::set_random_seed(1)
  model <- keras3::keras_model_sequential(input_shape = 3) |>
    keras3::layer_dense(units = 8, activation = "relu") |>
    keras3::layer_dense(units = 1, activation = "linear")

  est <- estimate_orbital_size(model, input_names = c("x1", "x2", "x3"))
  actual <- sum(nchar(orbital(model, input_names = c("x1", "x2", "x3"))))

  expect_type(est, "integer")
  # A freshly-constructed (never-trained) keras Dense layer's bias defaults
  # to exactly 0, which `build_linear_pred()` omits from the generated
  # expression entirely; a real trained model's biases are essentially never
  # exactly 0, so the estimate is calibrated against that (see the
  # `mlp(engine = "keras3")` test below), not this artificially-shorter case.
  expect_lt(est, actual * 1.3)
})

test_that("estimate_orbital_size requires input_names for bare keras3 Sequential", {
  skip_if_no_keras_estimate()

  model <- keras3::keras_model_sequential(input_shape = 3) |>
    keras3::layer_dense(units = 1)
  expect_snapshot(error = TRUE, estimate_orbital_size(model))
})

test_that("estimate_orbital_size scales with network depth/width for keras3", {
  skip_if_no_keras_estimate()

  keras3::set_random_seed(1)
  small <- keras3::keras_model_sequential(input_shape = 3) |>
    keras3::layer_dense(units = 4, activation = "relu") |>
    keras3::layer_dense(units = 1, activation = "linear")
  large <- keras3::keras_model_sequential(input_shape = 3) |>
    keras3::layer_dense(units = 40, activation = "relu") |>
    keras3::layer_dense(units = 1, activation = "linear")

  est_small <- estimate_orbital_size(small, input_names = c("x1", "x2", "x3"))
  est_large <- estimate_orbital_size(large, input_names = c("x1", "x2", "x3"))

  expect_gt(est_large, est_small)
})

test_that("estimate_orbital_size works for mlp(engine = keras3)", {
  skip_if_no_keras_estimate()
  skip_if_not_installed("parsnip")

  set.seed(1)
  keras3::set_random_seed(1)
  fit <- parsnip::fit(
    parsnip::set_mode(
      parsnip::set_engine(
        parsnip::mlp(epochs = 20, hidden_units = 8, activation = "relu"),
        "keras3"
      ),
      "regression"
    ),
    mpg ~ disp + hp,
    mtcars
  )

  est <- estimate_orbital_size(fit$fit, input_names = c("disp", "hp"))
  actual <- sum(nchar(orbital(fit)))

  expect_type(est, "integer")
  expect_equal(est, actual, tolerance = 0.1)
})
