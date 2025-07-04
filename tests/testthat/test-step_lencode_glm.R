test_that("step_lencode_glm works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$gear <- as.factor(mtcars$gear)
  mtcars$vs <- as.factor(mtcars$vs)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
      embed::step_lencode_glm(gear, vs, outcome = dplyr::vars(mpg)) |>
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("step_lencode_glm only calculates what is sufficient", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$gear <- as.factor(mtcars$gear)
  mtcars$vs <- as.factor(mtcars$vs)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
      embed::step_lencode_glm(gear, vs, outcome = dplyr::vars(mpg)) |>
      recipes::step_rm(gear) |>
      recipes::prep()
  )

  expect_identical(
    names(orbital(rec)),
    "vs"
  )
})

test_that("step_lencode_glm works with empty selections", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$gear <- as.factor(mtcars$gear)
  mtcars$vs <- as.factor(mtcars$vs)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
      embed::step_lencode_glm(outcome = dplyr::vars(mpg)) |>
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("spark - step_lencode_glm works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_lencode_glm <- dplyr::as_tibble(mtcars)
  mtcars_lencode_glm$gear <- as.factor(mtcars_lencode_glm$gear)
  mtcars_lencode_glm$vs <- as.factor(mtcars_lencode_glm$vs)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars_lencode_glm) |>
      embed::step_lencode_glm(gear, vs, outcome = dplyr::vars(mpg)) |>
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars_lencode_glm, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_lencode_glm")

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)
})

test_that("SQLite - step_lencode_glm works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  skip_on_cran()

  mtcars_lencode_glm <- dplyr::as_tibble(mtcars)
  mtcars_lencode_glm$gear <- as.factor(mtcars_lencode_glm$gear)
  mtcars_lencode_glm$vs <- as.factor(mtcars_lencode_glm$vs)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars_lencode_glm) |>
      embed::step_lencode_glm(gear, vs, outcome = dplyr::vars(mpg)) |>
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars_lencode_glm, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  mtcars_tbl <- dplyr::copy_to(con, mtcars_lencode_glm)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})

test_that("duckdb - step_lencode_glm works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  mtcars_lencode_glm <- dplyr::as_tibble(mtcars)
  mtcars_lencode_glm$gear <- as.factor(mtcars_lencode_glm$gear)
  mtcars_lencode_glm$vs <- as.factor(mtcars_lencode_glm$vs)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars_lencode_glm) |>
      embed::step_lencode_glm(gear, vs, outcome = dplyr::vars(mpg)) |>
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars_lencode_glm, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  mtcars_tbl <- dplyr::copy_to(con, mtcars_lencode_glm)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})

test_that("arrow - step_lencode_glm works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("arrow")

  mtcars_lencode_glm <- dplyr::as_tibble(mtcars)
  mtcars_lencode_glm$gear <- as.factor(mtcars_lencode_glm$gear)
  mtcars_lencode_glm$vs <- as.factor(mtcars_lencode_glm$vs)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars_lencode_glm) |>
      embed::step_lencode_glm(gear, vs, outcome = dplyr::vars(mpg)) |>
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars_lencode_glm, !!!orbital_inline(orbital(rec)))

  mtcars_tbl <- arrow::as_arrow_table(mtcars_lencode_glm)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)
})
