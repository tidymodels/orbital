test_that("step_corr works", {
  skip_if_not_installed("recipes")

  mtcars0 <- mtcars
  mtcars0$disp1 <- mtcars$disp

  rec_exp <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_corr(recipes::all_predictors()) |>
    recipes::prep()

  expect_null(orbital(rec_exp$steps[[1]]))

  rec <- recipes::recipe(mpg ~ ., data = mtcars0) |>
    recipes::step_corr(recipes::all_predictors()) |>
    recipes::prep()

  expect_null(orbital(rec$steps[[1]]))

  expect_identical(orbital(rec), orbital(rec_exp))
})

test_that("step_corr only calculates what is sufficient", {
  # Isn't needed as `step_corr()` doesn't produce code
  expect_true(TRUE)
})

test_that("step_corr works with empty selections", {
  # Isn't needed as `step_corr()` doesn't produce code
  expect_true(TRUE)
})

test_that("spark - step_corr works", {
  # Isn't needed as `step_corr()` doesn't produce code
  expect_true(TRUE)
})

test_that("SQLite - step_corr works", {
  # Isn't needed as `step_corr()` doesn't produce code
  expect_true(TRUE)
})

test_that("duckdb - step_corr works", {
  # Isn't needed as `step_corr()` doesn't produce code
  expect_true(TRUE)
})

test_that("arrow - step_corr works", {
  # Isn't needed as `step_corr()` doesn't produce code
  expect_true(TRUE)
})
