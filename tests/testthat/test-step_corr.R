test_that("step_corr works", {
  skip_if_not_installed("recipes")

  mtcars0 <- mtcars
  mtcars0$disp1 <- mtcars$disp

  rec_exp <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_corr(recipes::all_predictors()) %>%
    recipes::prep()

  expect_null(orbital(rec_exp$steps[[1]]))
  
  rec <- recipes::recipe(mpg ~ ., data = mtcars0) %>%
    recipes::step_corr(recipes::all_predictors()) %>%
    recipes::prep()
  
  expect_null(orbital(rec$steps[[1]]))

  expect_identical(orbital(rec), orbital(rec_exp))
})
