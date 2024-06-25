test_that("step_rm works", {
  skip_if_not_installed("recipes")

  mtcars0 <- mtcars
  mtcars0$zv <- 0

  rec_exp <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_rm(recipes::all_predictors()) %>%
    recipes::prep()

  expect_null(orbital(rec_exp$steps[[1]]))
  
  rec <- recipes::recipe(mpg ~ ., data = mtcars0) %>%
    recipes::step_rm(recipes::all_predictors()) %>%
    recipes::prep()
  
  expect_null(orbital(rec$steps[[1]]))

  expect_identical(orbital(rec), orbital(rec_exp))
})
test_that("multiplication works", {
  expect_equal(2 * 2, 4)
})
