test_that("boost_tree(), objective = regression, works with type = numeric", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("xgboost")

  bt_spec <- parsnip::boost_tree(mode = "regression", engine = "xgboost")

  bt_fit <- parsnip::fit(bt_spec, mpg ~ disp + vs + hp, mtcars)

  orb_obj <- orbital(bt_fit)

  # to avoid exact split values
  mtcars <- mtcars + 0.1

  preds <- predict(orb_obj, mtcars)
  exps <- predict(bt_fit, mtcars)

  expect_named(preds, ".pred")
  expect_type(preds$.pred, "double")

  exps <- as.data.frame(exps)

  rownames(preds) <- NULL
  rownames(exps) <- NULL

  expect_equal(
    preds,
    exps,
    tolerance = 0.0000001
  )
})

test_that("boost_tree(), objective = binary, works with type = class", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("xgboost")

  mtcars$vs <- factor(mtcars$vs)

  bt_spec <- parsnip::boost_tree(mode = "classification", engine = "xgboost")

  bt_fit <- parsnip::fit(bt_spec, vs ~ disp + mpg + hp, mtcars)

  orb_obj <- orbital(bt_fit, type = "class")

  # to avoid exact split values
  mtcars[, -8] <- mtcars[, -8] + 0.1

  preds <- predict(orb_obj, mtcars)
  exps <- predict(bt_fit, mtcars)

  expect_named(preds, ".pred_class")
  expect_type(preds$.pred_class, "character")

  expect_identical(
    preds$.pred_class,
    as.character(exps$.pred_class)
  )
})

test_that("boost_tree(), objective = multiclass, works with type = class", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("xgboost")

  bt_spec <- parsnip::boost_tree(mode = "classification", engine = "xgboost")

  bt_fit <- parsnip::fit(bt_spec, Species ~ ., iris)

  orb_obj <- orbital(bt_fit, type = "class")

  # to avoid exact split values
  iris[, -5] <- iris[, -5] + 0.05

  preds <- predict(orb_obj, iris)
  exps <- predict(bt_fit, iris)

  expect_named(preds, ".pred_class")
  expect_type(preds$.pred_class, "character")

  expect_identical(
    preds$.pred_class,
    as.character(exps$.pred_class)
  )
})

test_that("boost_tree(), objective = binary, works with type = prob", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("xgboost")

  mtcars$vs <- factor(mtcars$vs)

  bt_spec <- parsnip::boost_tree(mode = "classification", engine = "xgboost")

  bt_fit <- parsnip::fit(bt_spec, vs ~ disp + mpg + hp, mtcars)

  orb_obj <- orbital(bt_fit, type = "prob")

  # to avoid exact split values
  mtcars[, -8] <- mtcars[, -8] + 0.1

  preds <- predict(orb_obj, mtcars)
  exps <- predict(bt_fit, mtcars, type = "prob")

  expect_named(preds, c(".pred_0", ".pred_1"))
  expect_type(preds$.pred_0, "double")
  expect_type(preds$.pred_1, "double")

  exps <- as.data.frame(exps)

  rownames(preds) <- NULL
  rownames(exps) <- NULL

  expect_equal(
    preds,
    exps,
    tolerance = 0.0000001
  )
})

test_that("boost_tree(), objective = multiclass, works with type = prob", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("xgboost")

  bt_spec <- parsnip::boost_tree(mode = "classification", engine = "xgboost")

  bt_fit <- parsnip::fit(bt_spec, Species ~ ., iris)

  orb_obj <- orbital(bt_fit, type = "prob")

  # to avoid exact split values
  iris[, -5] <- iris[, -5] + 0.05

  preds <- predict(orb_obj, iris)
  exps <- predict(bt_fit, iris, type = "prob")

  expect_named(preds, paste0(".pred_", levels(iris$Species)))
  expect_type(preds$.pred_setosa, "double")
  expect_type(preds$.pred_versicolor, "double")
  expect_type(preds$.pred_virginica, "double")

  exps <- as.data.frame(exps)

  rownames(preds) <- NULL
  rownames(exps) <- NULL

  expect_equal(
    preds,
    exps,
    tolerance = 0.0000001
  )
})

test_that("boost_tree(xgboost) multiclass prob uses all default trees (#122)", {
  skip_if_not_installed("parsnip")

  skip_if_not_installed("tidypredict")
  skip_if_not_installed("xgboost")

  # Fit with default trees (parsnip default is 15)
  bt_spec_default <- parsnip::boost_tree(mode = "classification", engine = "xgboost")
  set.seed(1)
  bt_fit_default <- parsnip::fit(bt_spec_default, Species ~ ., iris)

  # Fit with explicit trees = 15

  bt_spec_explicit <- parsnip::boost_tree(mode = "classification", trees = 15, engine = "xgboost")
  set.seed(1)
  bt_fit_explicit <- parsnip::fit(bt_spec_explicit, Species ~ ., iris)

  orb_default <- orbital(bt_fit_default, type = "prob")
  orb_explicit <- orbital(bt_fit_explicit, type = "prob")

  # to avoid exact split values
  iris_test <- iris
  iris_test[, -5] <- iris_test[, -5] + 0.05

  preds_default <- predict(orb_default, iris_test)
  preds_explicit <- predict(orb_explicit, iris_test)

  expect_equal(preds_default, preds_explicit, tolerance = 0.0000001)
})

test_that("boost_tree(), objective = binary, works with type = c(class, prob)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("xgboost")

  mtcars$vs <- factor(mtcars$vs)

  bt_spec <- parsnip::boost_tree(mode = "classification", engine = "xgboost")

  bt_fit <- parsnip::fit(bt_spec, vs ~ disp + mpg + hp, mtcars)

  orb_obj <- orbital(bt_fit, type = c("class", "prob"))

  # to avoid exact split values
  mtcars[, -8] <- mtcars[, -8] + 0.1

  preds <- predict(orb_obj, mtcars)
  exps <- dplyr::bind_cols(
    predict(bt_fit, mtcars, type = c("class")),
    predict(bt_fit, mtcars, type = c("prob"))
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
    exps,
    tolerance = 0.0000001
  )
})

test_that("boost_tree(), objective = multiclass, works with type = c(class, prob)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("xgboost")

  bt_spec <- parsnip::boost_tree(mode = "classification", engine = "xgboost")

  bt_fit <- parsnip::fit(bt_spec, Species ~ ., iris)

  orb_obj <- orbital(bt_fit, type = c("class", "prob"))

  # to avoid exact split values
  iris[, -5] <- iris[, -5] + 0.05

  preds <- predict(orb_obj, iris)
  exps <- dplyr::bind_cols(
    predict(bt_fit, iris, type = c("class")),
    predict(bt_fit, iris, type = c("prob"))
  )

  expect_named(preds, c(".pred_class", paste0(".pred_", levels(iris$Species))))
  expect_type(preds$.pred_class, "character")
  expect_type(preds$.pred_setosa, "double")
  expect_type(preds$.pred_versicolor, "double")
  expect_type(preds$.pred_virginica, "double")

  exps <- as.data.frame(exps)
  exps$.pred_class <- as.character(exps$.pred_class)

  rownames(preds) <- NULL
  rownames(exps) <- NULL

  expect_equal(
    preds,
    exps,
    tolerance = 0.0000001
  )
})

test_that("boost_tree(xgboost) works with custom prefix", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("xgboost")

  bt_spec <- parsnip::boost_tree(mode = "regression", engine = "xgboost")

  bt_fit <- parsnip::fit(bt_spec, mpg ~ disp + vs + hp, mtcars)

  orb_obj <- orbital(bt_fit, prefix = "my_pred")

  preds <- predict(orb_obj, mtcars)

  expect_named(preds, "my_pred")
})
