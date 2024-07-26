test_that("step_impute_median works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_impute_median(recipes::all_predictors()) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("step_impute_median only calculates what is sufficient", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_impute_median(recipes::all_predictors()) %>%
    recipes::step_rm(disp) %>%
    recipes::prep()

  expect_identical(
    names(orbital(rec)),
    setdiff(names(mtcars), c("mpg", "disp"))
  )
})

test_that("step_impute_median works with empty selections", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_impute_median() %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("spark - step_impute_median works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_impute_median <- dplyr::as_tibble(mtcars)
  mtcars_impute_median[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars_impute_median) %>%
    recipes::step_impute_median(recipes::all_predictors()) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars_impute_median, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_impute_median")

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, res)
})

test_that("SQLite - step_impute_median works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")

  mtcars_impute_median <- dplyr::as_tibble(mtcars)
  mtcars_impute_median[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars_impute_median) %>%
    recipes::step_impute_median(recipes::all_predictors()) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars_impute_median, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  mtcars_tbl <- dplyr::copy_to(con, mtcars_impute_median)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})

test_that("duckdb - step_impute_median works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  mtcars_impute_median <- dplyr::as_tibble(mtcars)
  mtcars_impute_median[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars_impute_median) %>%
    recipes::step_impute_median(recipes::all_predictors()) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars_impute_median, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  mtcars_tbl <- dplyr::copy_to(con, mtcars_impute_median)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})

test_that("data.table - step_impute_median works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("dtplyr")
  
  `:=` <- data.table::`:=`

  mtcars_impute_median <- dplyr::as_tibble(mtcars)
  mtcars_impute_median[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars_impute_median) %>%
    recipes::step_impute_median(recipes::all_predictors()) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars_impute_median, !!!orbital_inline(orbital(rec)))

  mtcars_tbl <- dtplyr::lazy_dt(mtcars_impute_median)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, res)
})
