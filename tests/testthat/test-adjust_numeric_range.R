test_that("adjust_predictions_custom works - defaults", {
  skip_if_not_installed("tailor")

  tlr <- tailor::tailor() |>
    tailor::adjust_numeric_range()

  tlr_fit <- tailor::fit(
    tlr,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  res <- orbital(tlr_fit)

  expect_s3_class(res, "orbital_class")

  expect_identical(
    predict(tlr_fit, mtcars),
    predict(res, tibble::as_tibble(mtcars))
  )
})

test_that("adjust_predictions_custom works - lower_limit", {
  skip_if_not_installed("tailor")

  tlr <- tailor::tailor() |>
    tailor::adjust_numeric_range(lower_limit = 15)

  tlr_fit <- tailor::fit(
    tlr,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  res <- orbital(tlr_fit)

  expect_s3_class(res, "orbital_class")

  expect_identical(
    predict(tlr_fit, mtcars),
    predict(res, tibble::as_tibble(mtcars))
  )
})

test_that("adjust_predictions_custom works - upper_limit", {
  skip_if_not_installed("tailor")

  tlr <- tailor::tailor() |>
    tailor::adjust_numeric_range(upper_limit = 25)

  tlr_fit <- tailor::fit(
    tlr,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  res <- orbital(tlr_fit)

  expect_s3_class(res, "orbital_class")

  expect_identical(
    predict(tlr_fit, mtcars),
    predict(res, tibble::as_tibble(mtcars))
  )
})

test_that("adjust_predictions_custom works - both", {
  skip_if_not_installed("tailor")

  tlr <- tailor::tailor() |>
    tailor::adjust_numeric_range(lower_limit = 15, upper_limit = 25)

  tlr_fit <- tailor::fit(
    tlr,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  res <- orbital(tlr_fit)

  expect_s3_class(res, "orbital_class")

  expect_identical(
    predict(tlr_fit, mtcars),
    predict(res, tibble::as_tibble(mtcars))
  )
})
