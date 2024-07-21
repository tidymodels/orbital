test_that("step_pca_sparse works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$hp <- NULL

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      embed::step_pca_sparse(recipes::all_predictors()) %>%
      recipes::prep()
  )

  exp <- recipes::bake(rec, new_data = mtcars)

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))
  res <- res[names(exp)]

  expect_equal(res, exp)
})

test_that("step_pca_sparse works with more than 9 PCs", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")

  mtcars <- dplyr::as_tibble(mtcars)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      embed::step_pca_sparse(recipes::all_predictors()) %>%
      recipes::prep()
  )

  exp <- recipes::bake(rec, new_data = mtcars)

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))
  res <- res[names(exp)]

  expect_equal(res, exp)
})

test_that("spark - step_pca_sparse works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars0 <- dplyr::as_tibble(mtcars)
  mtcars0$hp <- NULL

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars0) %>%
      embed::step_pca_sparse(recipes::all_predictors()) %>%
      recipes::prep()
  )

  exp <- dplyr::mutate(mtcars0, !!!orbital_inline(orbital(rec)))
  
  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars0")

  res_spark <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_spark, exp)
})