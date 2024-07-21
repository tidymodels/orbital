test_that("step_dummy works", {
  skip_if_not_installed("recipes")

  mtcars1 <- dplyr::as_tibble(mtcars)

  mtcars1$gear <- as.character(mtcars1$gear)
  mtcars1$carb <- as.character(mtcars1$carb)

  rec <- recipes::recipe(mpg ~ ., data = mtcars1) %>%
    recipes::step_dummy(recipes::all_nominal_predictors()) %>%
    recipes::prep()

  exp <- recipes::bake(rec, new_data = mtcars1)
  
  res <- dplyr::mutate(mtcars1, !!!orbital_inline(orbital(rec)))
  res <- res[names(exp)]

  expect_equal(res, exp)
})

test_that("step_dummy works with `one_hot = TRUE`", {
  skip_if_not_installed("recipes")

  mtcars1 <- dplyr::as_tibble(mtcars)

  mtcars1$gear <- as.character(mtcars1$gear)
  mtcars1$carb <- as.character(mtcars1$carb)

  rec <- recipes::recipe(mpg ~ ., data = mtcars1) %>%
    recipes::step_dummy(recipes::all_nominal_predictors(), one_hot = TRUE) %>%
    recipes::prep()

  exp <- recipes::bake(rec, new_data = mtcars1)
  
  res <- dplyr::mutate(mtcars1, !!!orbital_inline(orbital(rec)))
  res <- res[names(exp)]

  expect_equal(res, exp)
})


test_that("step_dummy works with empty selections", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_dummy() %>%
    recipes::prep()

  exp <- recipes::bake(rec, new_data = mtcars)
  
  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))
  res <- res[names(exp)]

  expect_equal(res, exp)
})

test_that("spark - step_dummy works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars1 <- dplyr::as_tibble(mtcars)

  mtcars1$gear <- as.character(mtcars1$gear)
  mtcars1$carb <- as.character(mtcars1$carb)

  rec <- recipes::recipe(mpg ~ ., data = mtcars1) %>%
    recipes::step_dummy(recipes::all_nominal_predictors()) %>%
    recipes::prep()

  exp <- dplyr::mutate(mtcars1, !!!orbital_inline(orbital(rec)))
  
  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars1")

  res_spark <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_spark, exp)
})