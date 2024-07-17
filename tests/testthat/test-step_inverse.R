test_that("step_inverse works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_inverse(recipes::all_predictors()) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("step_inverse works with offset argument", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_inverse(recipes::all_predictors(), offset = 1) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("spark - step_inverse works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_inverse(recipes::all_predictors(), offset = 0.01) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars")

  res_spark <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_spark, res)
})



