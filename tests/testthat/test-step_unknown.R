test_that("step_unknown works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$gear <- letters[mtcars$gear]
  mtcars$carb <- letters[mtcars$carb]
  mtcars[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_unknown(recipes::all_nominal_predictors()) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]
  exp$gear <- as.character(exp$gear)
  exp$carb <- as.character(exp$carb)

  expect_equal(res, exp)
})

test_that("step_unknown works with empty selections", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$gear <- letters[mtcars$gear]
  mtcars$carb <- letters[mtcars$carb]
  mtcars[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_unknown() %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]
  exp$gear <- as.character(exp$gear)
  exp$carb <- as.character(exp$carb)

  expect_equal(res, exp)
})

test_that("spark - step_unknown works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_unknown <- dplyr::as_tibble(mtcars)
  mtcars_unknown$gear <- letters[mtcars$gear]
  mtcars_unknown$carb <- letters[mtcars$carb]
  mtcars_unknown[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars_unknown) %>%
    recipes::step_unknown(recipes::all_nominal_predictors()) %>%
    recipes::prep(strings_as_factors = FALSE)

  res <- dplyr::mutate(mtcars_unknown, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_unknown")

  res_spark <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_spark, res)
})
