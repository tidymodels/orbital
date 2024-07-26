test_that("step_adasyn works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("themis")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$vs <- as.factor(mtcars$vs)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    themis::step_adasyn(vs, skip = TRUE) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("step_adasyn errors with skip = FALSE", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("themis")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$vs <- as.factor(mtcars$vs)

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    themis::step_adasyn(vs, skip = FALSE) %>%
    recipes::prep()

  expect_snapshot(
    error = TRUE,
    orbital(rec)
  )
})

test_that("step_adasyn only calculates what is sufficient", {
  # Here for completeness
  # step_adasyn() doesn't work with empty selections
  # as it is a resampling step

  expect_true(TRUE)
})

test_that("step_adasyn works with empty selections", {
  # Here for completeness
  # step_adasyn() doesn't work with empty selections
  # as it is a resampling step

  expect_true(TRUE)
})

test_that("spark - step_adasyn works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("themis")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_adasyn <- dplyr::as_tibble(mtcars)
  mtcars_adasyn$vs <- as.factor(mtcars$vs)

  rec <- recipes::recipe(mpg ~ ., data = mtcars_adasyn) %>%
    themis::step_adasyn(vs, skip = TRUE) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars_adasyn, !!!orbital_inline(orbital(rec)))
  res$vs <- as.character(res$vs)

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_adasyn")

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, res)
})

test_that("SQLite - step_adasyn works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("themis")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")

  mtcars_adasyn <- dplyr::as_tibble(mtcars)
  mtcars_adasyn$vs <- as.factor(mtcars$vs)

  rec <- recipes::recipe(mpg ~ ., data = mtcars_adasyn) %>%
    themis::step_adasyn(vs, skip = TRUE) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars_adasyn, !!!orbital_inline(orbital(rec)))
  res$vs <- as.character(res$vs)

  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  mtcars_tbl <- dplyr::copy_to(con, mtcars_adasyn)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, res)

  DBI::dbDisconnect(con)
})
