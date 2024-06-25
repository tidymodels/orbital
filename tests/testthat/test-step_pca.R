test_that("step_pca works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$hp <- NULL

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_pca(recipes::all_predictors()) %>%
    recipes::prep()

  exp <- recipes::bake(rec, new_data = mtcars)
  
  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))
  res <- res[names(exp)]

  expect_equal(res, exp)
})

test_that("step_pca works with more than 9 PCs", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_pca(recipes::all_predictors()) %>%
    recipes::prep()

  exp <- recipes::bake(rec, new_data = mtcars)

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))
  res <- res[names(exp)]

  expect_equal(res, exp)
})
