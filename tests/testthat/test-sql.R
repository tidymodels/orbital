test_that("sql works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("dbplyr")
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() %>%
    workflows::add_recipe(rec_spec) %>%
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  obj <- orbital(wf_fit)

  con <- dbplyr::simulate_dbi()

  expect_snapshot(
    transform = pretty_print,
    orbital_sql(obj, con)
  )
})
