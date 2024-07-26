test_that("step_pca_sparse works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$hp <- NULL

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      embed::step_pca_sparse(recipes::all_predictors()) %>%
      recipes::prep()
  )

  exp <- recipes::bake(rec, new_data = mtcars)

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))
  res <- res[names(exp)]

  expect_equal(res, exp)
})

test_that("step_pca_sparse works with more than 9 PCs", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")

  mtcars <- dplyr::as_tibble(mtcars)

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      embed::step_pca_sparse(recipes::all_predictors()) %>%
      recipes::prep()
  )

  exp <- recipes::bake(rec, new_data = mtcars)

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))
  res <- res[names(exp)]

  expect_equal(res, exp)
})

test_that("step_pca_sparse only calculates what is sufficient", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$hp <- NULL

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      embed::step_pca_sparse(recipes::all_predictors()) %>%
      recipes::step_rm(PC1, PC3, PC5) %>%
      recipes::prep()
  )

  expect_identical(
    names(orbital(rec)),
    c("PC2", "PC4")
  )
})

test_that("step_pca_sparse works with empty selections", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars$hp <- NULL

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      embed::step_pca_sparse() %>%
      recipes::prep()
  )

  exp <- recipes::bake(rec, new_data = mtcars)

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))
  res <- res[names(exp)]

  expect_equal(res, exp)
})

test_that("spark - step_pca_sparse works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars0 <- dplyr::as_tibble(mtcars)
  mtcars0$hp <- NULL

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars0) %>%
      embed::step_pca_sparse(recipes::all_predictors()) %>%
      recipes::prep()
  )

  exp <- dplyr::mutate(mtcars0, !!!orbital_inline(orbital(rec)))
  
  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars0")

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, exp)
})

test_that("SQLite - step_pca_sparse works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("embed")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")

  mtcars0 <- dplyr::as_tibble(mtcars)
  mtcars0$hp <- NULL

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars0) %>%
      embed::step_pca_sparse(recipes::all_predictors()) %>%
      recipes::prep()
  )

  exp <- dplyr::mutate(mtcars0, !!!orbital_inline(orbital(rec)))
  
  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  mtcars_tbl <- dplyr::copy_to(con, mtcars0)

  res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_new, exp)

  DBI::dbDisconnect(con)
})