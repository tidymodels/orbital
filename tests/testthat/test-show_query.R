test_that("show_query works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  skip_on_cran()

  rec_spec <- recipes::recipe(mpg ~ disp, data = mtcars) |>
    recipes::step_impute_mean(recipes::all_numeric_predictors()) |>
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow(rec_spec, lm_spec)
  wf_fit <- parsnip::fit(wf_spec, data = mtcars)

  orbital_obj <- orbital(wf_fit)

  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")

  expect_snapshot(
    show_query(orbital_obj, con = con)
  )

  DBI::dbDisconnect(con)
})
