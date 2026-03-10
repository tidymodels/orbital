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

test_that("spark - adjust_predictions_custom works", {
  skip_if_not_installed("tailor")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  tlr <- tailor::tailor() |>
    tailor::adjust_numeric_range(lower_limit = 15, upper_limit = 25)

  tlr_fit <- tailor::fit(
    tlr,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  res <- orbital(tlr_fit)

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars")

  expect_identical(
    dplyr::collect(predict(res, mtcars_tbl)),
    predict(tlr_fit, mtcars)
  )
})

test_that("SQLite - adjust_predictions_custom works", {
  skip_if_not_installed("tailor")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  skip_on_cran()

  tlr <- tailor::tailor() |>
    tailor::adjust_numeric_range(lower_limit = 15, upper_limit = 25)

  tlr_fit <- tailor::fit(
    tlr,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  res <- orbital(tlr_fit)

  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  mtcars_tbl <- dplyr::copy_to(con, mtcars)

  expect_identical(
    dplyr::collect(predict(res, mtcars_tbl)),
    predict(tlr_fit, mtcars)
  )
  DBI::dbDisconnect(con)
})

test_that("duckdb - adjust_predictions_custom works", {
  skip_if_not_installed("tailor")
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  tlr <- tailor::tailor() |>
    tailor::adjust_numeric_range(lower_limit = 15, upper_limit = 25)

  tlr_fit <- tailor::fit(
    tlr,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  res <- orbital(tlr_fit)

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  mtcars_tbl <- dplyr::copy_to(con, mtcars)

  expect_identical(
    dplyr::collect(predict(res, mtcars_tbl)),
    predict(tlr_fit, mtcars)
  )
  DBI::dbDisconnect(con)
})

test_that("arrow - adjust_predictions_custom works", {
  skip_if_not_installed("tailor")
  skip_if_not_installed("arrow")

  tlr <- tailor::tailor() |>
    tailor::adjust_numeric_range(lower_limit = 15, upper_limit = 25)

  tlr_fit <- tailor::fit(
    tlr,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  res <- orbital(tlr_fit)

  mtcars_tbl <- arrow::as_arrow_table(mtcars)

  expect_identical(
    dplyr::as_tibble(dplyr::collect(predict(res, mtcars_tbl))),
    dplyr::as_tibble(predict(tlr_fit, mtcars))
  )
})

test_that("estimate_adj_chars works for numeric_range", {
  skip_if_not_installed("tailor")

  tlr <- tailor::tailor() |>
    tailor::adjust_numeric_range(lower_limit = 15, upper_limit = 25)

  tlr_fit <- tailor::fit(
    tlr,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  res <- orbital:::estimate_adj_chars(tlr_fit$adjustments[[1]])
  expect_type(res, "integer")
  expect_true(res > 0)
})

test_that("estimate_adj_chars works for numeric_range with no limits", {
  skip_if_not_installed("tailor")

  tlr <- tailor::tailor() |>
    tailor::adjust_numeric_range()

  tlr_fit <- tailor::fit(
    tlr,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  res <- orbital:::estimate_adj_chars(tlr_fit$adjustments[[1]])
  expect_identical(res, 0L)
})

test_that("estimate_orbital_size works for tailor", {
  skip_if_not_installed("tailor")

  tlr <- tailor::tailor() |>
    tailor::adjust_numeric_range(lower_limit = 15, upper_limit = 25)

  tlr_fit <- tailor::fit(
    tlr,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  res <- estimate_orbital_size(tlr_fit)
  expect_type(res, "integer")
  expect_true(res > 0)
})
