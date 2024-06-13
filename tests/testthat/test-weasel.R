test_that("weasel works", {
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow(rec_spec, lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  res <- weasel(wf_fit)

  expect_s3_class(res, "weasel_class")
  expect_true(is.character(res))
  expect_named(res)
})

test_that("weasel errors on non-trained workflow", {
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow(rec_spec, lm_spec)

  expect_snapshot(
    error = TRUE,
    weasel(wf_spec)
  )
})

test_that("weasel errors on wrong input", {
  expect_snapshot(
    error = TRUE,
    weasel(lm(mpg ~ ., data = mtcars))
  )
})

test_that("weasel printing works", {
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow(rec_spec, lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  expect_snapshot(
    weasel(wf_fit)
  )
})
