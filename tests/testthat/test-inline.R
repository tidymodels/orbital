test_that("orbital works with workflows - recipe", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("tidypredict")

  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() %>%
    workflows::add_recipe(rec_spec) %>%
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  obj <- orbital(wf_fit)

  res <- orbital_inline(obj)

  expect_s3_class(res, "quosures")
  expect_named(res, names(obj))
  expect_length(res, length(obj))
})
