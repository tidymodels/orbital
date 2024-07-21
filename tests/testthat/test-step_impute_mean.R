test_that("step_impute_mean works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_impute_mean(recipes::all_predictors()) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("step_impute_mean only calculates what is sufficient", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_impute_mean(recipes::all_predictors()) %>%
    recipes::step_rm(disp) %>%
    recipes::prep()

  expect_identical(
    names(orbital(rec)),
    setdiff(names(mtcars), c("mpg", "disp"))
  )
})

test_that("step_impute_mean works with empty selections", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_impute_mean() %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("spark - step_impute_mean works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_impute_mean <- dplyr::as_tibble(mtcars)
  mtcars_impute_mean[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars_impute_mean) %>%
    recipes::step_impute_mean(recipes::all_predictors()) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars_impute_mean, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_impute_mean")

  res_spark <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_spark, res)
})



