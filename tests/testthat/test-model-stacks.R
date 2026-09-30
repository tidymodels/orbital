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

test_that("orbital() errors when `type` doesn't match a model_stack's mode", {
  st <- fit_regression_stack()

  expect_snapshot(
    error = TRUE,
    orbital(st, type = "prob")
  )
})

test_that("prefix renames the blend model's own output but not member columns", {
  st <- fit_regression_stack()
  member_names <- names(st$member_fits)

  orb <- orbital(st, prefix = "out")

  expect_true("out" %in% names(orb))
  expect_identical(attr(orb, "pred_names"), "out")
  for (nm in member_names) {
    expect_true(nm %in% names(orb))
  }

  preds <- predict(orb, mtcars)
  exp <- predict(st, new_data = mtcars)$.pred

  expect_equal(preds$out, exp, tolerance = 1e-6)
})

test_that("separate_trees propagates into a stack member that has trees", {
  skip_if_not_installed("ranger")

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

  rf_wf <- workflows::workflow(
    rec,
    parsnip::rand_forest(trees = 5) |>
      parsnip::set_engine("ranger") |>
      parsnip::set_mode("regression")
  )
  rf_res <- tune::fit_resamples(
    rf_wf,
    resamples = folds,
    control = stacks::control_stack_resamples()
  )

  st <- suppressWarnings(
    stacks::stacks() |>
      stacks::add_candidates(lin_res) |>
      stacks::add_candidates(rf_res) |>
      stacks::blend_predictions() |>
      stacks::fit_members()
  )

  orb <- orbital(st, separate_trees = TRUE)
  preds <- predict(orb, mtcars)
  exp <- as.data.frame(predict(st, new_data = mtcars))

  rownames(preds) <- NULL
  rownames(exp) <- NULL

  expect_equal(preds, exp, tolerance = 1e-6)
})

test_that("orbital() wraps a member build failure with the member's name", {
  skip_if_not_installed("kknn")

  set.seed(1)
  knn_wf <- workflows::workflow(
    recipes::recipe(mpg ~ wt + cyl, mtcars),
    parsnip::nearest_neighbor(mode = "regression") |>
      parsnip::set_engine("kknn")
  )
  knn_fit <- parsnip::fit(knn_wf, mtcars)

  coefs <- parsnip::fit(
    parsnip::linear_reg() |> parsnip::set_engine("lm"),
    mpg ~ knn_res,
    data.frame(mpg = mtcars$mpg, knn_res = predict(knn_fit, mtcars)$.pred)
  )

  st <- structure(
    list(
      mode = "regression",
      member_fits = list(knn_res = knn_fit),
      coefs = coefs
    ),
    class = "model_stack"
  )

  expect_snapshot(error = TRUE, orbital(st))
})

test_that("orbital() errors when stack members produce colliding equation names", {
  set.seed(1)
  wf <- workflows::workflow(
    recipes::recipe(mpg ~ wt + cyl, mtcars),
    parsnip::linear_reg() |> parsnip::set_engine("lm")
  )
  fit <- parsnip::fit(wf, mtcars)

  coefs <- parsnip::fit(
    parsnip::linear_reg() |> parsnip::set_engine("lm"),
    mpg ~ dup,
    data.frame(mpg = mtcars$mpg, dup = predict(fit, mtcars)$.pred)
  )

  # Two entries under the same name: a real stack never produces this (member
  # names are unique), but this exercises the collision guard directly rather
  # than leaving it dead code.
  st <- structure(
    list(
      mode = "regression",
      member_fits = list(dup = fit, dup = fit),
      coefs = coefs
    ),
    class = "model_stack"
  )

  expect_snapshot(error = TRUE, orbital(st))
})

test_that("check_fitted_stack requires member_fits", {
  expect_snapshot(
    error = TRUE,
    orbital:::check_fitted_stack(list(member_fits = NULL, coefs = NULL))
  )
  expect_snapshot(
    error = TRUE,
    orbital:::check_fitted_stack(list(member_fits = list(), coefs = NULL))
  )
})

test_that("check_fitted_stack requires coefs to be a fitted model_fit", {
  expect_snapshot(
    error = TRUE,
    orbital:::check_fitted_stack(
      list(member_fits = list(a = 1), coefs = list())
    )
  )
})

test_that("rename_stack_member_eqs renames a regression member's own output and suffixes the rest", {
  eq <- c(a = "1 + `b`", b = "2")
  attr(eq, "pred_names") <- "a"
  class(eq) <- "orbital"

  res <- orbital:::rename_stack_member_eqs(eq, "regression", "mem")

  expect_named(res, c("mem", "b_mem"))
  expect_identical(unclass(res)[["mem"]], "1 + b_mem")
})

test_that("rename_stack_member_eqs suffixes every classification output", {
  eq <- c(.pred_yes = "0.7", .pred_no = "1 - `.pred_yes`")
  attr(eq, "pred_names") <- c(".pred_yes", ".pred_no")
  class(eq) <- "orbital"

  res <- orbital:::rename_stack_member_eqs(eq, "classification", "mem")

  expect_named(res, c(".pred_yes_mem", ".pred_no_mem"))
  expect_identical(unclass(res)[[".pred_no_mem"]], "1 - .pred_yes_mem")
})

test_that("rename_stack_member_eqs replaces longest names first so a short name can't clobber a longer one", {
  eq <- c(norm = "1", norm2 = "`norm` + 1")
  attr(eq, "pred_names") <- "norm2"
  class(eq) <- "orbital"

  res <- orbital:::rename_stack_member_eqs(eq, "classification", "mem")

  expect_named(res, c("norm_mem", "norm2_mem"))
  expect_identical(unclass(res)[["norm2_mem"]], "norm_mem + 1")
})

test_that("binary classification model_stack respects type = 'class' alone", {
  st <- fit_classification_stack()
  data <- modeldata::two_class_dat

  orb <- orbital(st, type = "class")
  preds <- as.data.frame(predict(orb, data))

  exp <- as.data.frame(predict(st, new_data = data, type = "class"))
  exp$.pred_class <- as.character(exp$.pred_class)
  preds$.pred_class <- as.character(preds$.pred_class)

  rownames(preds) <- NULL
  rownames(exp) <- NULL

  expect_named(preds, ".pred_class")
  expect_equal(preds, exp)
})

test_that("binary classification model_stack respects type = 'prob' alone", {
  st <- fit_classification_stack()
  data <- modeldata::two_class_dat

  orb <- orbital(st, type = "prob")
  preds <- as.data.frame(predict(orb, data))

  exp <- as.data.frame(predict(st, new_data = data, type = "prob"))

  rownames(preds) <- NULL
  rownames(exp) <- NULL

  expect_named(preds, names(exp))
  expect_equal(preds, exp, tolerance = 1e-6)
})

test_that("regression model_stack works with three distinct member model types", {
  skip_if_not_installed("ranger")

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

  rf_wf <- workflows::workflow(
    rec,
    parsnip::rand_forest(trees = 5) |>
      parsnip::set_engine("ranger") |>
      parsnip::set_mode("regression")
  )
  rf_res <- tune::fit_resamples(
    rf_wf,
    resamples = folds,
    control = stacks::control_stack_resamples()
  )

  st <- suppressWarnings(
    stacks::stacks() |>
      stacks::add_candidates(lin_res) |>
      stacks::add_candidates(tree_res) |>
      stacks::add_candidates(rf_res) |>
      stacks::blend_predictions() |>
      stacks::fit_members()
  )

  orb <- orbital(st)
  preds <- predict(orb, mtcars)
  exp <- as.data.frame(predict(st, new_data = mtcars))

  rownames(preds) <- NULL
  rownames(exp) <- NULL

  expect_equal(preds, exp, tolerance = 1e-6)
})
