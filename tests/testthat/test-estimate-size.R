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
  expect_snapshot(error = TRUE, estimate_orbital_size(lm(mpg ~ ., mtcars)))
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
