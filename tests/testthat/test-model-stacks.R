skip_if_not_installed("stacks")
skip_if_not_installed("tune")
skip_if_not_installed("rsample")
skip_if_not_installed("yardstick")
skip_if_not_installed("glmnet")
skip_if_not_installed("rpart")
skip_if_not_installed("modeldata")

fit_regression_stack <- function() {
  set.seed(1)
  folds <- rsample::vfold_cv(mtcars, v = 3)
  rec <- recipes::recipe(mpg ~ ., data = mtcars)

  lin_wf <- workflows::workflow(
    rec,
    parsnip::linear_reg(penalty = tune::tune(), mixture = 1) |>
      parsnip::set_engine("glmnet")
  )
  lin_res <- tune::tune_grid(
    lin_wf,
    resamples = folds,
    grid = 3,
    control = stacks::control_stack_grid()
  )

  tree_wf <- workflows::workflow(
    rec,
    parsnip::decision_tree(cost_complexity = tune::tune()) |>
      parsnip::set_engine("rpart") |>
      parsnip::set_mode("regression")
  )
  tree_res <- tune::tune_grid(
    tree_wf,
    resamples = folds,
    grid = 3,
    control = stacks::control_stack_grid()
  )

  suppressWarnings(
    stacks::stacks() |>
      stacks::add_candidates(lin_res) |>
      stacks::add_candidates(tree_res) |>
      stacks::blend_predictions() |>
      stacks::fit_members()
  )
}

fit_classification_stack <- function() {
  set.seed(1)
  data <- modeldata::two_class_dat
  folds <- rsample::vfold_cv(data, v = 3)
  rec <- recipes::recipe(Class ~ ., data = data)

  lr_wf <- workflows::workflow(
    rec,
    parsnip::logistic_reg(penalty = tune::tune(), mixture = 1) |>
      parsnip::set_engine("glmnet")
  )
  lr_res <- tune::tune_grid(
    lr_wf,
    resamples = folds,
    grid = 3,
    control = stacks::control_stack_grid(),
    metrics = yardstick::metric_set(yardstick::roc_auc)
  )

  tree_wf <- workflows::workflow(
    rec,
    parsnip::decision_tree(cost_complexity = tune::tune()) |>
      parsnip::set_engine("rpart") |>
      parsnip::set_mode("classification")
  )
  tree_res <- tune::tune_grid(
    tree_wf,
    resamples = folds,
    grid = 3,
    control = stacks::control_stack_grid(),
    metrics = yardstick::metric_set(yardstick::roc_auc)
  )

  suppressWarnings(
    stacks::stacks() |>
      stacks::add_candidates(lr_res) |>
      stacks::add_candidates(tree_res) |>
      stacks::blend_predictions() |>
      stacks::fit_members()
  )
}

fit_multiclass_stack <- function() {
  set.seed(1)
  data <- iris
  folds <- rsample::vfold_cv(data, v = 3)
  rec <- recipes::recipe(Species ~ ., data = data)

  mn_wf <- workflows::workflow(
    rec,
    parsnip::multinom_reg(penalty = tune::tune(), mixture = 1) |>
      parsnip::set_engine("glmnet")
  )
  mn_res <- tune::tune_grid(
    mn_wf,
    resamples = folds,
    grid = 3,
    control = stacks::control_stack_grid()
  )

  tree_wf <- workflows::workflow(
    rec,
    parsnip::decision_tree(cost_complexity = tune::tune()) |>
      parsnip::set_engine("rpart") |>
      parsnip::set_mode("classification")
  )
  tree_res <- tune::tune_grid(
    tree_wf,
    resamples = folds,
    grid = 3,
    control = stacks::control_stack_grid()
  )

  suppressWarnings(
    stacks::stacks() |>
      stacks::add_candidates(mn_res) |>
      stacks::add_candidates(tree_res) |>
      stacks::blend_predictions() |>
      stacks::fit_members()
  )
}

test_that("multiclass classification model_stack matches predict()", {
  st <- fit_multiclass_stack()
  data <- iris

  orb <- orbital(st, type = c("class", "prob"))
  preds <- as.data.frame(predict(orb, data))

  exp <- dplyr::bind_cols(
    predict(st, new_data = data, type = "class"),
    predict(st, new_data = data, type = "prob")
  )
  exp <- as.data.frame(exp)
  exp$.pred_class <- as.character(exp$.pred_class)

  preds <- preds[names(exp)]
  preds$.pred_class <- as.character(preds$.pred_class)

  rownames(preds) <- NULL
  rownames(exp) <- NULL

  expect_equal(preds, exp, tolerance = 1e-6)
})

test_that("orbital() errors early on invalid `type` for a model_stack", {
  st <- fit_regression_stack()

  expect_snapshot(
    error = TRUE,
    orbital(st, type = "bogus")
  )
})

test_that("regression model_stack matches predict()", {
  st <- fit_regression_stack()

  orb <- orbital(st)
  preds <- predict(orb, mtcars)
  exp <- as.data.frame(predict(st, new_data = mtcars))

  rownames(preds) <- NULL
  rownames(exp) <- NULL

  expect_equal(preds, exp, tolerance = 1e-6)
})

test_that("binary classification model_stack matches predict()", {
  st <- fit_classification_stack()
  data <- modeldata::two_class_dat

  orb <- orbital(st, type = c("class", "prob"))
  preds <- as.data.frame(predict(orb, data))

  exp <- dplyr::bind_cols(
    predict(st, new_data = data, type = "class"),
    predict(st, new_data = data, type = "prob")
  )
  exp <- as.data.frame(exp)
  exp$.pred_class <- as.character(exp$.pred_class)

  preds <- preds[names(exp)]
  preds$.pred_class <- as.character(preds$.pred_class)

  rownames(preds) <- NULL
  rownames(exp) <- NULL

  expect_equal(preds, exp, tolerance = 1e-6)
})

test_that("orbital() errors on a stack that hasn't been fit_members()", {
  skip_if_not_installed("stacks")

  set.seed(1)
  folds <- rsample::vfold_cv(mtcars, v = 3)
  rec <- recipes::recipe(mpg ~ ., data = mtcars)
  lin_wf <- workflows::workflow(
    rec,
    parsnip::linear_reg(penalty = tune::tune(), mixture = 1) |>
      parsnip::set_engine("glmnet")
  )
  lin_res <- tune::tune_grid(
    lin_wf,
    resamples = folds,
    grid = 3,
    control = stacks::control_stack_grid()
  )
  st <- suppressWarnings(
    stacks::stacks() |>
      stacks::add_candidates(lin_res) |>
      stacks::blend_predictions()
  )

  expect_snapshot(
    error = TRUE,
    orbital(st)
  )
})
