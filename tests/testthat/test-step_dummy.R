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

test_that("step_dummy only calculates what is sufficient", {
  skip_if_not_installed("recipes")

  mtcars1 <- dplyr::as_tibble(mtcars)

  mtcars1$gear <- as.character(mtcars1$gear)
  mtcars1$carb <- as.character(mtcars1$carb)

  rec <- recipes::recipe(mpg ~ ., data = mtcars1) %>%
    recipes::step_dummy(recipes::all_nominal_predictors()) %>%
    recipes::step_rm(dplyr::ends_with("4")) %>%
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

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, exp)
})

test_that("SQLite - step_dummy works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")

  mtcars1 <- dplyr::as_tibble(mtcars)

  mtcars1$gear <- as.character(mtcars1$gear)
  mtcars1$carb <- as.character(mtcars1$carb)

  rec <- recipes::recipe(mpg ~ ., data = mtcars1) %>%
    recipes::step_dummy(recipes::all_nominal_predictors()) %>%
    recipes::prep()

  exp <- dplyr::mutate(mtcars1, !!!orbital_inline(orbital(rec)))
  
  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  mtcars_tbl <- dplyr::copy_to(con, mtcars1)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, exp)

  DBI::dbDisconnect(con)
})

test_that("duckdb - step_dummy works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  mtcars1 <- dplyr::as_tibble(mtcars)

  mtcars1$gear <- as.character(mtcars1$gear)
  mtcars1$carb <- as.character(mtcars1$carb)

  rec <- recipes::recipe(mpg ~ ., data = mtcars1) %>%
    recipes::step_dummy(recipes::all_nominal_predictors()) %>%
    recipes::prep()

  exp <- dplyr::mutate(mtcars1, !!!orbital_inline(orbital(rec)))
  
  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  mtcars_tbl <- dplyr::copy_to(con, mtcars1)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, exp)

  DBI::dbDisconnect(con)
})

test_that("data.table - step_dummy works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("dtplyr")
  
  `:=` <- data.table::`:=`

  mtcars1 <- dplyr::as_tibble(mtcars)

  mtcars1$gear <- as.character(mtcars1$gear)
  mtcars1$carb <- as.character(mtcars1$carb)

  rec <- recipes::recipe(mpg ~ ., data = mtcars1) %>%
    recipes::step_dummy(recipes::all_nominal_predictors()) %>%
    recipes::prep()

  exp <- dplyr::mutate(mtcars1, !!!orbital_inline(orbital(rec)))
  
  mtcars_tbl <- dtplyr::lazy_dt(mtcars1)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, exp)
})