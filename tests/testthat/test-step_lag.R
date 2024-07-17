test_that("step_lag works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_lag(recipes::all_predictors(), lag = 1:4) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("spark - step_lag works", {
  # For completeness
  # lag is weird for spark
})
