test_that("step_spline_convex works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("splines2")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_spline_convex(disp, hp, deg_free = 4) |>
    recipes::prep()

  exp <- recipes::bake(rec, new_data = mtcars)

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))
  res <- res[names(exp)]

  expect_equal(res, exp)
})

test_that("step_spline_convex only calculates what is sufficient", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("splines2")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_spline_convex(disp, deg_free = 4) |>
    recipes::step_rm(disp_2, disp_4) |>
    recipes::prep()

  expect_identical(
    names(orbital(rec)),
    c("disp_1", "disp_3")
  )
})

test_that("step_spline_convex works with empty selections", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("splines2")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_spline_convex() |>
    recipes::prep()

  exp <- recipes::bake(rec, new_data = mtcars)

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))
  res <- res[names(exp)]

  expect_equal(res, exp)
})

test_that("spark - step_spline_convex works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("splines2")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_spline_convex(disp, deg_free = 4) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars")

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)
})

test_that("SQLite - step_spline_convex works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("splines2")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  skip_on_cran()

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_spline_convex(disp, deg_free = 4) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  mtcars_tbl <- dplyr::copy_to(con, mtcars)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})

test_that("duckdb - step_spline_convex works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("splines2")
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_spline_convex(disp, deg_free = 4) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  mtcars_tbl <- dplyr::copy_to(con, mtcars)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})

test_that("arrow - step_spline_convex works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("splines2")
  skip_if_not_installed("arrow")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_spline_convex(disp, deg_free = 4) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  mtcars_tbl <- arrow::as_arrow_table(mtcars)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)
})
