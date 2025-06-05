test_that("step_nzv works", {
  skip_if_not_installed("recipes")

  mtcars0 <- mtcars
  mtcars0$zv <- 0

  rec_exp <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_nzv(recipes::all_predictors()) %>%
    recipes::prep()

  expect_null(orbital(rec_exp$steps[[1]]))

  rec <- recipes::recipe(mpg ~ ., data = mtcars0) %>%
    recipes::step_nzv(recipes::all_predictors()) %>%
    recipes::prep()

  expect_null(orbital(rec$steps[[1]]))

  expect_identical(orbital(rec), orbital(rec_exp))
})

test_that("step_nzv only calculates what is sufficient", {
  # Isn't needed as `step_nzv()` doesn't produce code
  expect_true(TRUE)
})

test_that("step_nzv works with empty selections", {
  # Isn't needed as `step_nzv()` doesn't produce code
  expect_true(TRUE)
})

test_that("spark - step_nzv works", {
  # Isn't needed as `step_nzv()` doesn't produce code
  expect_true(TRUE)
})

test_that("SQLite - step_nzv works", {
  # Isn't needed as `step_nzv()` doesn't produce code
  expect_true(TRUE)
})

test_that("duckdb - step_nzv works", {
  # Isn't needed as `step_nzv()` doesn't produce code
  expect_true(TRUE)
})

test_that("arrow - step_nzv works", {
  # Isn't needed as `step_nzv()` doesn't produce code
  expect_true(TRUE)
})
