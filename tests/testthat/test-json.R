test_that("read and write json works", {
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())
  
  lm_spec <- parsnip::linear_reg()
  
  wf_spec <- workflows::workflow(rec_spec, lm_spec)
  
  wf_fit <- parsnip::fit(wf_spec, mtcars)
  
  weasel_obj <- weasel(wf_fit)
  
  tmp_file <- tempfile()
  
  weasel_json_write(weasel_obj, tmp_file)
  
  new <- weasel_json_read(tmp_file)

  expect_identical(new, weasel_obj)
})
