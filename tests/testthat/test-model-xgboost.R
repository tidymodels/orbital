test_that("boost_tree(), objective = binary:logistic, works with type = class", {
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

test_that("boost_tree(), objective = multi:softprob, works with type = class", {
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

test_that("boost_tree(), objective = binary:logistic, works with type = prob", {
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

test_that("boost_tree(), objective = multi:softprob, works with type = prob", {
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

test_that("boost_tree(), objective = binary:logistic, works with type = c(class, prob)", {
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

test_that("boost_tree(), objective = multi:softprob, works with type = c(class, prob)", {
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
