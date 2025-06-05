test_that("type argument checking works", {
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("workflows")
  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() |>
    workflows::add_variables(outcomes = "mpg", predictors = everything()) |>
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  expect_no_error(
    orbital(wf_fit, type = "numeric")
  )

  expect_snapshot(
    error = TRUE,
    orbital(wf_fit, type = "invalid")
  )
  expect_snapshot(
    error = TRUE,
    orbital(wf_fit, type = "class")
  )
  expect_snapshot(
    error = TRUE,
    orbital(wf_fit, type = c("class", "numeric"))
  )

  lr_spec <- parsnip::logistic_reg()

  mtcars$vs <- factor(mtcars$vs)

  wf_spec <- workflows::workflow() |>
    workflows::add_variables(outcomes = "vs", predictors = "disp") |>
    workflows::add_model(lr_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  expect_no_error(
    orbital(wf_fit, type = "class")
  )

  expect_no_error(
    orbital(wf_fit, type = c("class", "prob"))
  )

  expect_snapshot(
    error = TRUE,
    orbital(wf_fit, type = "invalid")
  )
  expect_snapshot(
    error = TRUE,
    orbital(wf_fit, type = "numeric")
  )
  expect_snapshot(
    error = TRUE,
    orbital(wf_fit, type = c("class", "numeric"))
  )
})

test_that("pred_names) works with type = c(class, prob) and recipes", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")
  skip_if_not_installed("recipes")
  skip_if_not_installed("tidypredict")

  mtcars$vs <- factor(mtcars$vs)

  lr_spec <- parsnip::logistic_reg()

  rec_spec <- recipes::recipe(vs ~ disp + mpg + hp, mtcars) |>
    recipes::step_center(disp, mpg, hp)

  wf_spec <- workflows::workflow(rec_spec, lr_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  orb_obj <- orbital(wf_fit, type = c("class", "prob"))

  preds <- predict(orb_obj, mtcars)
  exps <- dplyr::bind_cols(
    predict(wf_fit, mtcars, type = c("class")),
    predict(wf_fit, mtcars, type = c("prob"))
  )

  expect_named(preds, c(".pred_class", ".pred_0", ".pred_1"))
  expect_type(preds$.pred_class, "character")
  expect_type(preds$.pred_0, "double")
  expect_type(preds$.pred_1, "double")

  exps <- as.data.frame(exps)
  exps$.pred_class <- as.character(exps$.pred_class)

  rownames(preds) <- NULL
  rownames(exps) <- NULL

  expect_equal(
    preds,
    exps
  )
})
