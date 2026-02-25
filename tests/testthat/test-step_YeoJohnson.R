test_that("step_YeoJohnson works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(~., data = mtcars) |>
    recipes::step_YeoJohnson(mpg, disp) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("step_YeoJohnson works with negative values", {
  skip_if_not_installed("recipes")

  dat <- dplyr::tibble(
    x = c(-5, -2, -1, 0, 1, 2, 5),
    y = c(1, 2, 3, 4, 5, 6, 7)
  )

  rec <- recipes::recipe(~., data = dat) |>
    recipes::step_YeoJohnson(x) |>
    recipes::prep()

  res <- dplyr::mutate(dat, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = dat)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("step_YeoJohnson works with lambda near 0", {
  skip_if_not_installed("recipes")

  dat <- dplyr::tibble(x = c(-2, -1, 0, 1, 2, 5))

  rec <- recipes::recipe(~., data = dat) |>
    recipes::step_YeoJohnson(x) |>
    recipes::prep()

  rec$steps[[1]]$lambdas <- c(x = 0.0001)

  res <- dplyr::mutate(dat, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = dat)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})
test_that("step_YeoJohnson works with lambda near 2", {
  skip_if_not_installed("recipes")

  dat <- dplyr::tibble(x = c(-5, -2, -1, 0, 1, 2))

  rec <- recipes::recipe(~., data = dat) |>
    recipes::step_YeoJohnson(x) |>
    recipes::prep()

  rec$steps[[1]]$lambdas <- c(x = 1.9999)

  res <- dplyr::mutate(dat, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = dat)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("step_YeoJohnson only calculates what is sufficient", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(~., data = mtcars) |>
    recipes::step_YeoJohnson(mpg, disp) |>
    recipes::step_rm(mpg) |>
    recipes::prep()

  expect_identical(
    names(orbital(rec)),
    "disp"
  )
})

test_that("step_YeoJohnson works with empty selections", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(~., data = mtcars) |>
    recipes::step_YeoJohnson() |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("spark - step_YeoJohnson works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(~., data = mtcars) |>
    recipes::step_YeoJohnson(mpg, disp) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars")

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)
})

test_that("SQLite - step_YeoJohnson works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  skip_on_cran()

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(~., data = mtcars) |>
    recipes::step_YeoJohnson(mpg, disp) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  mtcars_tbl <- dplyr::copy_to(con, mtcars)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})

test_that("duckdb - step_YeoJohnson works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(~., data = mtcars) |>
    recipes::step_YeoJohnson(mpg, disp) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  mtcars_tbl <- dplyr::copy_to(con, mtcars)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})

test_that("arrow - step_YeoJohnson works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("arrow")

  mtcars <- dplyr::as_tibble(mtcars)

  rec <- recipes::recipe(~., data = mtcars) |>
    recipes::step_YeoJohnson(mpg, disp) |>
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  mtcars_tbl <- arrow::as_arrow_table(mtcars)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) |>
    dplyr::collect()

  expect_equal(res_new, res)
})
