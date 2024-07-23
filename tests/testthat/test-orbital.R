test_that("orbital works with workflows - recipe", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("workflows")
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() %>%
    workflows::add_recipe(rec_spec) %>%
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  res <- orbital(wf_fit)

  expect_s3_class(res, "orbital_class")
  expect_true(is.character(res))
  expect_named(res)
  expect_length(res, 1 + (ncol(mtcars) - 1))
})

test_that("orbital works with workflows - formula", {
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("workflows")
  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() %>%
    workflows::add_formula(mpg ~ .) %>%
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  res <- orbital(wf_fit)

  expect_s3_class(res, "orbital_class")
  expect_true(is.character(res))
  expect_named(res, ".pred")
  expect_length(res, 1)
})

test_that("orbital works with workflows - variables", {
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("workflows")
  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() %>%
    workflows::add_variables(outcomes = "mpg", predictors = everything()) %>%
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  res <- orbital(wf_fit)

  expect_s3_class(res, "orbital_class")
  expect_true(is.character(res))
  expect_named(res, ".pred")
  expect_length(res, 1)
})

test_that("orbital errors on non-trained workflow", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("workflows")
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow(rec_spec, lm_spec)

  expect_snapshot(
    error = TRUE,
    orbital(wf_spec)
  )
})

test_that("orbital works with recipe", {
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("recipes")
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  rec_prep <- recipes::prep(rec_spec)

  res <- orbital(rec_prep)

  expect_s3_class(res, "orbital_class")
  expect_true(is.character(res))
  expect_named(res)
})

test_that("orbital errors untrained recipe", {
  skip_if_not_installed("recipes")
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  expect_snapshot(
    error = TRUE,
    orbital(rec_spec)
  )
})

test_that("orbital works with parsnip", {
  skip_if_not_installed("tidypredict")
  lm_spec <- parsnip::linear_reg()

  lm_fit <- parsnip::fit(lm_spec, mpg ~ ., data = mtcars)
  
  res <- orbital(lm_fit)

  expect_s3_class(res, "orbital_class")
  expect_true(is.character(res))
  expect_named(res, ".pred")
})

test_that("orbital errors on non-trained parsnip", {
  skip_if_not_installed("parsnip")
  lm_spec <- parsnip::linear_reg()
  
  expect_snapshot(
    error = TRUE,
    orbital(lm_spec)
  )
})

test_that("orbital errors nicely on post-processing", {
  skip_if_not_installed("workflows")
  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() %>%
    workflows::add_formula(mpg ~ .) %>%
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  # fake post-processing happening
  wf_fit$post$actions <- list(thing = 1)
  
  expect_snapshot(
    error = TRUE,
    orbital(wf_fit)
  )
})

test_that("orbital errors on wrong input", {
  expect_snapshot(
    error = TRUE,
    orbital(lm(mpg ~ ., data = mtcars))
  )
})

test_that("orbital printing works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("workflows")
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow(rec_spec, lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  expect_snapshot(
    orbital(wf_fit)
  )

  expect_snapshot(
    print(orbital(wf_fit), digits = 2)
  )
})
