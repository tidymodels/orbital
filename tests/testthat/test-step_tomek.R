test_that("step_tomek works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("themis")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$vs <- as.factor(mtcars$vs)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    themis::step_tomek(vs, skip = TRUE) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("step_tomek errors with skip = FALSE", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("themis")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$vs <- as.factor(mtcars$vs)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    themis::step_tomek(vs, skip = FALSE) %>%
    recipes::prep()

  expect_snapshot(
    error = TRUE,
    orbital(rec)
  )
})

test_that("step_tomek works works with empty selections", {
  # Here for completeness
  # step_tomek() doesn't work with empty selections
  # as it is a resampling step

  expect_true(TRUE)
})

test_that("spark - step_tomek works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("themis")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_tomek <- dplyr::as_tibble(mtcars)
  mtcars_tomek$vs <- as.factor(mtcars$vs)

  rec <- recipes::recipe(mpg ~ ., data = mtcars_tomek) %>%
    themis::step_tomek(vs, skip = TRUE) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars_tomek, !!!orbital_inline(orbital(rec)))
  res$vs <- as.character(res$vs)

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_tomek")

  res_spark <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_spark, res)
})
