test_that("spline_extract_poly_coefs extracts polynomial coefficients", {
  x <- seq(0, 1, length.out = 20)
  y <- 2 + 3 * x + 4 * x^2 + 5 * x^3
  coefs <- spline_extract_poly_coefs(x, y, degree = 3)

  expect_equal(coefs, c(2, 3, 4, 5), tolerance = 1e-10)
})

test_that("spline_extract_poly_coefs handles all-zero values", {
  x <- seq(0, 1, length.out = 20)
  y <- rep(0, 20)
  coefs <- spline_extract_poly_coefs(x, y, degree = 3)

  expect_length(coefs, 4)
  expect_equal(coefs, rep(0, 4))
})

test_that("spline_build_poly_expr builds polynomial expressions", {
  coefs <- c(2, 3, 4, 5)
  expr <- spline_build_poly_expr("x", coefs)

  expect_identical(expr, "2 + 3 * x + 4 * x^2 + 5 * x^3")
})

test_that("spline_build_poly_expr handles all-zero coefficients", {
  coefs <- c(0, 0, 0, 0)
  expr <- spline_build_poly_expr("x", coefs)

  expect_equal(expr, "0")
})

test_that("spline_build_case_when builds case_when expressions", {
  all_knots <- c(0, 1, 2)
  coefs_list <- list(
    c(1, 2, 0, 0),
    c(3, 4, 0, 0)
  )
  expr <- spline_build_case_when("x", all_knots, coefs_list)

  expect_identical(
    expr,
    "dplyr::case_when(x <= 1 ~ 1 + 2 * x, TRUE ~ 3 + 4 * x)"
  )
})
