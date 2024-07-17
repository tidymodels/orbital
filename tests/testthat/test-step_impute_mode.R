test_that("step_impute_mode works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$gear <- letters[mtcars$gear]
  mtcars$carb <- letters[mtcars$carb]
  mtcars[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_impute_mode(recipes::all_nominal_predictors()) %>%
    recipes::prep(strings_as_factors = FALSE)

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("spark - step_impute_mode works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_impute_mode <- dplyr::as_tibble(mtcars)
  mtcars_impute_mode$gear <- letters[mtcars$gear]
  mtcars_impute_mode$carb <- letters[mtcars$carb]
  mtcars_impute_mode[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars_impute_mode) %>%
    recipes::step_impute_mode(recipes::all_nominal_predictors()) %>%
    recipes::prep(strings_as_factors = FALSE)

  res <- dplyr::mutate(mtcars_impute_mode, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_impute_mode")

  res_spark <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_spark, res)
})



