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

test_that("format_double round-trips whenever a decimal can", {
  set.seed(1234)
  vals <- c(runif(500), rnorm(500) * 1e5, runif(500) * 1e-8)

  # R's parser is not correctly rounded, so some doubles no decimal literal
  # reaches at all. Every one that any `%g` width reaches must round-trip.
  reachable <- vapply(
    vals,
    function(x) any(as.numeric(sprintf("%.*g", 1:17, x)) == x),
    logical(1)
  )
  round_trips <- as.numeric(vapply(vals, orbital:::format_double, "")) == vals

  expect_identical(round_trips[reachable], rep(TRUE, sum(reachable)))
})

test_that("format_double round-trips more often than digits17", {
  set.seed(1234)
  vals <- runif(500)

  expect_gt(
    sum(as.numeric(vapply(vals, orbital:::format_double, "")) == vals),
    sum(as.numeric(sprintf("%.17g", vals)) == vals)
  )
})

test_that("format_double picks the shortest readable form", {
  expect_equal(orbital:::format_double(10), "10")
  expect_equal(orbital:::format_double(0.3), "0.3")
  expect_equal(orbital:::format_double(-1e-08), "-1e-08")
})

test_that("deparse_exact round-trips expressions", {
  eq <- rlang::expr(dplyr::case_when(
    x > 1.234567890123456 ~ 0.98765432109876,
    y <= -3.5e-08 ~ 42,
    .default = 0.3
  ))

  expect_identical(rlang::parse_expr(orbital:::deparse_exact(eq)), eq)
})

test_that("deparse_exact keeps missing arguments", {
  eq <- rlang::expr(x[, 1.5])

  expect_identical(rlang::parse_expr(orbital:::deparse_exact(eq)), eq)
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
