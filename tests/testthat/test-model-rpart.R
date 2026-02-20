test_that("decision_tree(rpart) works with type = numeric", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("rpart")

  spec <- parsnip::decision_tree("regression", "rpart")

  fit <- parsnip::fit(spec, mpg ~ disp + vs + hp, mtcars)

  orb_obj <- orbital(fit)

  preds <- predict(orb_obj, mtcars)
  exps <- predict(fit, mtcars)

  expect_named(preds, ".pred")
  expect_type(preds$.pred, "double")

  exps <- as.data.frame(exps)

  rownames(preds) <- NULL
  rownames(exps) <- NULL

  expect_equal(
    preds,
    exps
  )
})

test_that("decision_tree(rpart) works with type = class", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("rpart")

  mtcars$vs <- factor(mtcars$vs)

  spec <- parsnip::decision_tree("classification", "rpart")

  fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)

  orb_obj <- orbital(fit, type = "class")

  preds <- predict(orb_obj, mtcars)
  exps <- predict(fit, mtcars)

  expect_named(preds, ".pred_class")
  expect_type(preds$.pred_class, "character")

  expect_identical(
    preds$.pred_class,
    as.character(exps$.pred_class)
  )
})

test_that("decision_tree(rpart) works with type = prob", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("rpart")

  mtcars$vs <- factor(mtcars$vs)

  spec <- parsnip::decision_tree("classification", "rpart")

  fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)

  orb_obj <- orbital(fit, type = "prob")

  preds <- predict(orb_obj, mtcars)
  exps <- predict(fit, mtcars, type = "prob")

  expect_named(preds, c(".pred_0", ".pred_1"))
  expect_type(preds$.pred_0, "double")
  expect_type(preds$.pred_1, "double")

  exps <- as.data.frame(exps)

  rownames(preds) <- NULL
  rownames(exps) <- NULL

  expect_equal(
    preds,
    exps
  )
})

test_that("decision_tree(rpart) works with type = c(class, prob)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("rpart")

  mtcars$vs <- factor(mtcars$vs)

  spec <- parsnip::decision_tree("classification", "rpart")

  fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)

  orb_obj <- orbital(fit, type = c("class", "prob"))

  preds <- predict(orb_obj, mtcars)
  exps <- dplyr::bind_cols(
    predict(fit, mtcars, type = c("class")),
    predict(fit, mtcars, type = c("prob"))
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

test_that("decision_tree(rpart) works with custom prefix", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("rpart")

  spec <- parsnip::decision_tree("regression", "rpart")

  fit <- parsnip::fit(spec, mpg ~ disp + vs + hp, mtcars)

  orb_obj <- orbital(fit, prefix = "my_pred")

  preds <- predict(orb_obj, mtcars)

  expect_named(preds, "my_pred")
})
