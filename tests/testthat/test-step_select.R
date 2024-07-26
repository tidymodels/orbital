test_that("step_select works", {
  skip_if_not_installed("recipes")

  mtcars0 <- mtcars
  mtcars0$zv <- 0

  rec_exp <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_select(recipes::all_predictors()) %>%
    recipes::prep()

  expect_null(orbital(rec_exp$steps[[1]]))
  
  rec <- recipes::recipe(mpg ~ ., data = mtcars0) %>%
    recipes::step_select(recipes::all_predictors()) %>%
    recipes::prep()
  
  expect_null(orbital(rec$steps[[1]]))

  expect_identical(orbital(rec), orbital(rec_exp))
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