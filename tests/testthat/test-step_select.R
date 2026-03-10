test_that("step_select works", {
  # The step is predecated
  expect_true(TRUE)
})

test_that("step_select only calculates what is sufficient", {
  # Isn't needed as `step_select()` doesn't produce code
  expect_true(TRUE)
})

test_that("step_select works with empty selections", {
  # Isn't needed as `step_select()` doesn't produce code
  expect_true(TRUE)
})

test_that("spark - step_select works", {
  # Isn't needed as `step_select()` doesn't produce code
  expect_true(TRUE)
})

test_that("SQLite - step_select works", {
  # Isn't needed as `step_select()` doesn't produce code
  expect_true(TRUE)
})

test_that("duckdb - step_select works", {
  # Isn't needed as `step_select()` doesn't produce code
  expect_true(TRUE)
})

test_that("arrow - step_select works", {
  # Isn't needed as `step_select()` doesn't produce code
  expect_true(TRUE)
})

test_that("estimate_step_chars works for step_select", {
  skip_if_not_installed("recipes")

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_select(recipes::all_predictors()) |>
    recipes::prep()

  res <- orbital:::estimate_step_chars(rec$steps[[1]])
  expect_identical(res, 0L)
})
