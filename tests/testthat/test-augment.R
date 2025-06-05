test_that("augment() works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("workflows")

  mtcars <- dplyr::as_tibble(mtcars)

  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() %>%
    workflows::add_recipe(rec_spec) %>%
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  obj <- orbital(wf_fit)

  res <- augment(obj, mtcars)

  exp <- dplyr::bind_cols(
    predict(obj, mtcars),
    mtcars
  )

  expect_identical(res, exp)
})

test_that("spark - augment() works", {
  # Doesn't work because tables can't row_number() easily
})

test_that("SQLite - augment() works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("workflows")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  skip_on_cran()

  mtcars <- dplyr::as_tibble(mtcars)

  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() %>%
    workflows::add_recipe(rec_spec) %>%
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  obj <- orbital(wf_fit)

  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  mtcars_tbl <- dplyr::copy_to(con, mtcars)

  res <- augment(obj, mtcars_tbl)

  exp <- dplyr::bind_cols(
    predict(obj, mtcars),
    mtcars
  )

  expect_s3_class(res, "tbl_lazy")
  expect_identical(dplyr::collect(res), exp)

  DBI::dbDisconnect(con)
})

test_that("duckdb - augment() works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("workflows")
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  mtcars <- dplyr::as_tibble(mtcars)

  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() %>%
    workflows::add_recipe(rec_spec) %>%
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  obj <- orbital(wf_fit)

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  mtcars_tbl <- dplyr::copy_to(con, mtcars)

  res <- augment(obj, mtcars_tbl)

  exp <- dplyr::bind_cols(
    predict(obj, mtcars),
    mtcars
  )

  expect_identical(dplyr::collect(res), exp)

  DBI::dbDisconnect(con)
})

test_that("arrow - augment() works", {
  # Doesn't work, getting the following warning:
  # Warning: Expression row_number() not supported in Arrow; pulling data into R
})
