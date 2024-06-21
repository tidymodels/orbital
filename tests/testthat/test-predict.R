test_that("orbital works with workflows - recipe", {
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() %>%
    workflows::add_recipe(rec_spec) %>%
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  obj <- orbital(wf_fit)

  expect_identical(
    mtcars %>% orbital_predict(obj),
    mtcars %>% dplyr::mutate(!!!orbital_inline(obj)) %>% dplyr::select(.pred)
  )
})
