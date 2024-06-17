test_that("weasel works with workflows - recipe", {
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() %>%
    workflows::add_recipe(rec_spec) %>%
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  obj <- weasel(wf_fit)

  expect_identical(
    mtcars %>% weasel_mutate(obj),
    mtcars %>% dplyr::mutate(!!!weasel_inline(obj))
  )

  expect_identical(
    mtcars %>% weasel_mutate(obj, only_pred = TRUE),
    mtcars %>% dplyr::mutate(!!!weasel_inline(obj)) %>% dplyr::select(.pred)
  )
})
