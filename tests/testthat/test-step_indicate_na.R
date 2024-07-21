test_that("step_indicate_na works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_indicate_na(recipes::all_predictors()) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("step_indicate_na only calculates what is sufficient", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_indicate_na(recipes::all_predictors()) %>%
    recipes::step_rm(dplyr::contains("d_d")) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})


test_that("step_indicate_na works with empty selections", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_indicate_na() %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("spark - step_indicate_na works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_indicate_na <- dplyr::as_tibble(mtcars)
  mtcars_indicate_na[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars_indicate_na) %>%
    recipes::step_indicate_na(recipes::all_predictors()) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars_indicate_na, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_indicate_na")

  res_spark <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_spark, res)
})



