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
