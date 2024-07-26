test_that("step_lencode_mixed works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$gear <- as.factor(mtcars$gear)
  mtcars$vs <- as.factor(mtcars$vs)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      embed::step_lencode_mixed(gear, vs, outcome = dplyr::vars(mpg)) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("step_lencode_mixed only calculates what is sufficient", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$gear <- as.factor(mtcars$gear)
  mtcars$vs <- as.factor(mtcars$vs)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      embed::step_lencode_mixed(gear, vs, outcome = dplyr::vars(mpg)) %>%
      recipes::step_rm(gear) %>%
      recipes::prep()
  )
    
  expect_identical(
    names(orbital(rec)),
    "vs"
  )
})

test_that("step_lencode_mixed works with empty selections", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$gear <- as.factor(mtcars$gear)
  mtcars$vs <- as.factor(mtcars$vs)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      embed::step_lencode_mixed(outcome = dplyr::vars(mpg)) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("spark - step_lencode_mixed works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_lencode_mixed <- dplyr::as_tibble(mtcars)
  mtcars_lencode_mixed$gear <- as.factor(mtcars_lencode_mixed$gear)
  mtcars_lencode_mixed$vs <- as.factor(mtcars_lencode_mixed$vs)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars_lencode_mixed) %>%
      embed::step_lencode_mixed(gear, vs, outcome = dplyr::vars(mpg)) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars_lencode_mixed, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_lencode_mixed")

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, res)
})

test_that("SQLite - step_lencode_mixed works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")

  mtcars_lencode_mixed <- dplyr::as_tibble(mtcars)
  mtcars_lencode_mixed$gear <- as.factor(mtcars_lencode_mixed$gear)
  mtcars_lencode_mixed$vs <- as.factor(mtcars_lencode_mixed$vs)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars_lencode_mixed) %>%
      embed::step_lencode_mixed(gear, vs, outcome = dplyr::vars(mpg)) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars_lencode_mixed, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  mtcars_tbl <- dplyr::copy_to(con, mtcars_lencode_mixed)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})

test_that("duckdb - step_lencode_mixed works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  mtcars_lencode_mixed <- dplyr::as_tibble(mtcars)
  mtcars_lencode_mixed$gear <- as.factor(mtcars_lencode_mixed$gear)
  mtcars_lencode_mixed$vs <- as.factor(mtcars_lencode_mixed$vs)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars_lencode_mixed) %>%
      embed::step_lencode_mixed(gear, vs, outcome = dplyr::vars(mpg)) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars_lencode_mixed, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  mtcars_tbl <- dplyr::copy_to(con, mtcars_lencode_mixed)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})
