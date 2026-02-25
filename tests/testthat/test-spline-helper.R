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
    "dplyr::case_when(x <= 1 ~ 1 + 2 * x, .default = 3 + 4 * x)"
  )
})

test_that("spline_helper produces accurate results for natural splines", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("splines2")

  df <- data.frame(x = seq(100, 350, length.out = 30))

  rec <- recipes::recipe(~x, data = df) |>
    recipes::step_spline_natural(x, deg_free = 4) |>
    recipes::prep()

  step_obj <- rec$steps[[1]]
  expected <- recipes::bake(rec, new_data = df)

  all_vars <- c("x_1", "x_2", "x_3", "x_4")
  result <- spline_helper(step_obj, all_vars, splines2::naturalSpline)

  actual <- df
  for (i in seq_along(result)) {
    expr <- parse(text = result[i])
    actual[[names(result)[i]]] <- eval(expr, envir = actual)
  }

  expect_equal(
    dplyr::as_tibble(actual[all_vars]),
    expected[all_vars],
    tolerance = 1e-10
  )
})

test_that("spline_helper filters to requested variables", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("splines2")

  df <- data.frame(x = seq(100, 350, length.out = 20))

  rec <- recipes::recipe(~x, data = df) |>
    recipes::step_spline_natural(x, deg_free = 4) |>
    recipes::prep()

  step_obj <- rec$steps[[1]]
  result <- spline_helper(step_obj, c("x_1", "x_3"), splines2::naturalSpline)

  expect_identical(names(result), c("x_1", "x_3"))
})

test_that("spline_helper handles multiple variables", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("splines2")

  df <- data.frame(x = seq(100, 350, length.out = 20), z = runif(20))

  rec <- recipes::recipe(~ x + z, data = df) |>
    recipes::step_spline_natural(x, z, deg_free = 3) |>
    recipes::prep()

  step_obj <- rec$steps[[1]]
  all_vars <- c("x_1", "x_2", "x_3", "z_1", "z_2", "z_3")
  result <- spline_helper(step_obj, all_vars, splines2::naturalSpline)

  expect_identical(names(result), all_vars)
})

test_that("spline_helper returns NULL for empty selection", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("splines2")

  df <- data.frame(x = seq(100, 350, length.out = 20))

  rec <- recipes::recipe(~x, data = df) |>
    recipes::step_spline_natural(x, deg_free = 4) |>
    recipes::prep()

  step_obj <- rec$steps[[1]]
  result <- spline_helper(step_obj, c("y_1"), splines2::naturalSpline)

  expect_null(result)
})

test_that("spline_helper handles varying numbers of knots", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("splines2")

  df <- data.frame(x = seq(0, 100, length.out = 50))

  for (deg_free in c(2, 3, 5, 8)) {
    rec <- recipes::recipe(~x, data = df) |>
      recipes::step_spline_natural(x, deg_free = deg_free) |>
      recipes::prep()

    step_obj <- rec$steps[[1]]
    expected <- recipes::bake(rec, new_data = df)

    all_vars <- paste0("x_", seq_len(deg_free))
    result <- spline_helper(step_obj, all_vars, splines2::naturalSpline)

    actual <- df
    for (i in seq_along(result)) {
      expr <- parse(text = result[i])
      actual[[names(result)[i]]] <- eval(expr, envir = actual)
    }

    expect_equal(
      dplyr::as_tibble(actual[all_vars]),
      expected[all_vars],
      tolerance = 1e-10
    )
  }
})
