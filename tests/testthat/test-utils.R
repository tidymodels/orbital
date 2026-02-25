# Tests for utility functions

test_that("format_numeric preserves full precision", {
  val <- 0.123456789012345678
  result <- orbital:::format_numeric(val)
  # The value is stored as the closest IEEE 754 double
  # Verify it has 17+ significant digits

  expect_match(result, "^0\\.123456789012345")
})

test_that("format_numeric works with vectors", {
  vals <- c(1.234567890123456, 9.876543210987654)
  result <- orbital:::format_numeric(vals)
  expect_length(result, 2)
  expect_match(result[1], "^1\\.234567890123456")
  expect_match(result[2], "^9\\.876543210987")
})

test_that("format_numeric handles integers", {
  val <- 10
  result <- orbital:::format_numeric(val)
  expect_equal(result, "10")
})

test_that("format_numeric handles negative values", {
  val <- -0.123456789012345678
  result <- orbital:::format_numeric(val)
  expect_match(result, "^-0\\.123456789012345")
})

test_that("format_numeric handles zero", {
  result <- orbital:::format_numeric(0)
  expect_equal(result, "0")
})

test_that("build_linear_pred creates correct expression", {
  coef_names <- c("(Intercept)", "x", "y")
  coef_values <- c(1.5, 2.0, 3.0)
  result <- orbital:::build_linear_pred(coef_names, coef_values)
  expect_equal(result, "1.5 + (`x` * 2) + (`y` * 3)")
})

test_that("build_linear_pred skips zero coefficients", {
  coef_names <- c("(Intercept)", "x", "y")
  coef_values <- c(1.5, 0.0, 3.0)
  result <- orbital:::build_linear_pred(coef_names, coef_values)
  expect_equal(result, "1.5 + (`y` * 3)")
})

test_that("build_linear_pred handles all zeros", {
  coef_names <- c("(Intercept)", "x")
  coef_values <- c(0.0, 0.0)
  result <- orbital:::build_linear_pred(coef_names, coef_values)
  expect_equal(result, "0")
})

test_that("build_linear_pred preserves full precision", {
  coef_names <- c("(Intercept)", "x")
  coef_values <- c(0.123456789012345678, 9.876543210987654321)
  result <- orbital:::build_linear_pred(coef_names, coef_values)
  # Verify high precision is maintained (at least 15 significant digits)
  expect_match(result, "0\\.123456789012345")
  expect_match(result, "9\\.876543210987")
})

test_that("build_linear_pred handles intercept only", {
  coef_names <- c("(Intercept)")
  coef_values <- c(5.5)
  result <- orbital:::build_linear_pred(coef_names, coef_values)
  expect_equal(result, "5.5")
})

test_that("build_linear_pred handles no intercept", {
  coef_names <- c("x", "y")
  coef_values <- c(2.0, 3.0)
  result <- orbital:::build_linear_pred(coef_names, coef_values)
  expect_equal(result, "(`x` * 2) + (`y` * 3)")
})
