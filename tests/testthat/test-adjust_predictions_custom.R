test_that("adjust_predictions_custom works", {
  skip_if_not_installed("tailor")

  tlr <- tailor::tailor() |>
    tailor::adjust_predictions_custom(
      double = mpg * 2,
      half = mpg / 2
    )

  tlr_fit <- tailor::fit(
    tlr,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  res <- orbital(tlr_fit)

  expect_s3_class(res, "orbital_class")
  expect_identical(
    unclass(res),
    c(double = "mpg * 2", half = "mpg/2")
  )

  expect_identical(
    predict(tlr_fit, mtcars),
    predict(res, tibble::as_tibble(mtcars))
  )
})

test_that("empty selections work", {
  skip_if_not_installed("tailor")

  tlr_1 <- tailor::tailor() |>
    tailor::adjust_predictions_custom() |>
    tailor::adjust_predictions_custom(
      half = mpg / 2
    )

  tlr_1_fit <- tailor::fit(
    tlr_1,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  tlr_0 <- tailor::tailor() |>
    tailor::adjust_predictions_custom(
      half = mpg / 2
    )

  tlr_0_fit <- tailor::fit(
    tlr_0,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  expect_identical(
    orbital(tlr_0_fit),
    orbital(tlr_1_fit)
  )
})
