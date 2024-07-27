test_that("step_discretize works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[1, ] <- NA

  suppressWarnings(
    rec <- recipes::recipe(~ ., data = mtcars) %>%
      recipes::step_discretize(mpg, disp, min_unique = 4) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]
  exp$mpg <- as.character(exp$mpg)
  exp$disp <- as.character(exp$disp)

  expect_equal(res, exp)
})

test_that("step_discretize works num_breaks = 2", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[1, ] <- NA

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      recipes::step_discretize(vs, am, min_unique = 1, num_breaks = 2) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]
  exp$am <- as.character(exp$am)
  exp$vs <- as.character(exp$vs)

  expect_equal(res, exp)
})

test_that("step_discretize works when min_unique is too high", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[1, ] <- NA

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      recipes::step_discretize(mpg, disp, min_unique = 100) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("step_discretize only calculates what is sufficient", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      recipes::step_discretize(mpg, disp, min_unique = 4) %>%
      recipes::step_rm(mpg) %>%
      recipes::prep()
  )

  expect_identical(
    names(orbital(rec)),
    "disp"
  )
})

test_that("step_discretize works with empty selections", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[1, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_discretize() %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("spark - step_discretize works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_discretize <- dplyr::as_tibble(mtcars)
  mtcars_discretize[1, ] <- NA

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars_discretize) %>%
      recipes::step_discretize(mpg, disp, min_unique = 4) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars_discretize, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_discretize")

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, res)
})

test_that("SQLite - step_discretize works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")

  mtcars_discretize <- dplyr::as_tibble(mtcars)
  mtcars_discretize[1, ] <- NA

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars_discretize) %>%
      recipes::step_discretize(mpg, disp, min_unique = 4) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars_discretize, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  mtcars_tbl <- dplyr::copy_to(con, mtcars_discretize)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})

test_that("duckdb - step_discretize works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  mtcars_discretize <- dplyr::as_tibble(mtcars)
  mtcars_discretize[1, ] <- NA

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars_discretize) %>%
      recipes::step_discretize(mpg, disp, min_unique = 4) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars_discretize, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  mtcars_tbl <- dplyr::copy_to(con, mtcars_discretize)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})

test_that("arrow - step_discretize works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("arrow")

  mtcars_discretize <- dplyr::as_tibble(mtcars)
  mtcars_discretize[1, ] <- NA

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars_discretize) %>%
      recipes::step_discretize(mpg, disp, min_unique = 4) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars_discretize, !!!orbital_inline(orbital(rec)))

  mtcars_tbl <- arrow::as_arrow_table(mtcars_discretize)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, res)
})
