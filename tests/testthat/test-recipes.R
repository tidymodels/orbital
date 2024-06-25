test_that("multiplication works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")
  skip_if_not_installed("tidypredict")

  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_impute_knn(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow(rec_spec, lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  expect_snapshot(
    error = TRUE,
    orbital(wf_fit)
  )
})
