test_that("step_lincomb works", {
  skip_if_not_installed("recipes")

  mtcars0 <- mtcars
  mtcars0$zv <- 0

  rec_exp <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_lincomb(recipes::all_predictors()) |>
    recipes::prep()

  expect_null(orbital(rec_exp$steps[[1]]))

  rec <- recipes::recipe(mpg ~ ., data = mtcars0) |>
    recipes::step_lincomb(recipes::all_predictors()) |>
    recipes::prep()

  expect_null(orbital(rec$steps[[1]]))

  expect_identical(orbital(rec), orbital(rec_exp))
})

test_that("step_lincomb only calculates what is sufficient", {
  # Isn't needed as `step_lincomb()` doesn't produce code
  expect_true(TRUE)
})

test_that("step_lincomb works with empty selections", {
  # Isn't needed as `step_lincomb()` doesn't produce code
  expect_true(TRUE)
})

test_that("spark - step_lincomb works", {
  # Isn't needed as `step_lincomb()` doesn't produce code
  expect_true(TRUE)
})

test_that("SQLite - step_lincomb works", {
  # Isn't needed as `step_lincomb()` doesn't produce code
  expect_true(TRUE)
})

test_that("duckdb - step_lincomb works", {
  # Isn't needed as `step_lincomb()` doesn't produce code
  expect_true(TRUE)
})

test_that("arrow - step_lincomb works", {
  # Isn't needed as `step_lincomb()` doesn't produce code
  expect_true(TRUE)
})

test_that("estimate_step_chars works for step_lincomb", {
  skip_if_not_installed("recipes")

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_lincomb(recipes::all_predictors()) |>
    recipes::prep()

  res <- orbital:::estimate_step_chars(rec$steps[[1]])
  expect_identical(res, 0L)
})
