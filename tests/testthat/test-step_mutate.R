test_that("step_mutate works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(~., data = mtcars) |>
    recipes::step_mutate(mpg = mpg + 5, disp4 = disp / 4) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("step_mutate only calculates what is sufficient", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(~., data = mtcars) |>
    recipes::step_mutate(mpg = mpg + 5, disp4 = disp / 4) |>
    recipes::step_rm(disp4) |>
    recipes::prep()

  expect_identical(
    names(orbital(rec)),
    "mpg"
  )
})

test_that("step_mutate works with empty selections", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_mutate() |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("spark - step_mutate works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_mutate(mpg = mpg + 5, disp4 = disp / 4) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars")

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)
})

test_that("SQLite - step_mutate works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  skip_on_cran()

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_mutate(mpg = mpg + 5, disp4 = disp / 4) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  mtcars_tbl <- dplyr::copy_to(con, mtcars)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})

test_that("duckdb - step_mutate works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_mutate(mpg = mpg + 5, disp4 = disp / 4) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  mtcars_tbl <- dplyr::copy_to(con, mtcars)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})

test_that("arrow - step_mutate works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("arrow")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_mutate(mpg = mpg + 5, disp4 = disp / 4) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  mtcars_tbl <- arrow::as_arrow_table(mtcars)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)
})
