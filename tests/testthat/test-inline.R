test_that("weasel works with workflows - recipe", {
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() %>%
    workflows::add_recipe(rec_spec) %>%
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  obj <- weasel(wf_fit)

  res <- weasel_inline(obj)

  expect_s3_class(res, "quosures")
  expect_named(res, names(obj))
  expect_length(res, length(obj))
})
