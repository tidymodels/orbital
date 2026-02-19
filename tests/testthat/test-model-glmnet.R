test_that("logistic_reg(engine = 'glmnet') works with type = class", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("glmnet")

  mtcars$vs <- factor(mtcars$vs)

  spec <- parsnip::logistic_reg(penalty = 0.01, engine = "glmnet")

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

test_that("logistic_reg(engine = 'glmnet') works with type = prob", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("glmnet")

  mtcars$vs <- factor(mtcars$vs)

  spec <- parsnip::logistic_reg(penalty = 0.01, engine = "glmnet")

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
    exps,
    tolerance = 0.0000001
  )
})

test_that("logistic_reg(engine = 'glmnet') works with type = c(class, prob)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("glmnet")

  mtcars$vs <- factor(mtcars$vs)

  spec <- parsnip::logistic_reg(penalty = 0.01, engine = "glmnet")

  fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)

  orb_obj <- orbital(fit, type = c("class", "prob"))

  preds <- predict(orb_obj, mtcars)
  exps <- dplyr::bind_cols(
    predict(fit, mtcars, type = "class"),
    predict(fit, mtcars, type = "prob")
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

test_that("logistic_reg(engine = 'glmnet') works with custom prefix", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("glmnet")

  mtcars$vs <- factor(mtcars$vs)

  spec <- parsnip::logistic_reg(penalty = 0.01, engine = "glmnet")

  fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)

  orb_obj <- orbital(fit, type = c("class", "prob"), prefix = "my_pred")

  preds <- predict(orb_obj, mtcars)

  expect_named(preds, c("my_pred_class", "my_pred_0", "my_pred_1"))
})

test_that("multinom_reg(engine = 'glmnet') works with type = class", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("glmnet")

  spec <- parsnip::multinom_reg(penalty = 0.01, engine = "glmnet")

  fit <- parsnip::fit(spec, Species ~ ., iris)

  orb_obj <- orbital(fit, type = "class")

  preds <- predict(orb_obj, iris)
  exps <- predict(fit, iris)

  expect_named(preds, ".pred_class")
  expect_type(preds$.pred_class, "character")

  expect_identical(
    preds$.pred_class,
    as.character(exps$.pred_class)
  )
})

test_that("multinom_reg(engine = 'glmnet') works with type = prob", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("glmnet")

  spec <- parsnip::multinom_reg(penalty = 0.01, engine = "glmnet")

  fit <- parsnip::fit(spec, Species ~ ., iris)

  orb_obj <- orbital(fit, type = "prob")

  preds <- predict(orb_obj, iris)
  exps <- predict(fit, iris, type = "prob")

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

test_that("multinom_reg(engine = 'glmnet') works with type = c(class, prob)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("glmnet")

  spec <- parsnip::multinom_reg(penalty = 0.01, engine = "glmnet")

  fit <- parsnip::fit(spec, Species ~ ., iris)

  orb_obj <- orbital(fit, type = c("class", "prob"))

  preds <- predict(orb_obj, iris)
  exps <- dplyr::bind_cols(
    predict(fit, iris, type = "class"),
    predict(fit, iris, type = "prob")
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

test_that("multinom_reg(engine = 'glmnet') works with custom prefix", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("glmnet")

  spec <- parsnip::multinom_reg(penalty = 0.01, engine = "glmnet")

  fit <- parsnip::fit(spec, Species ~ ., iris)

  orb_obj <- orbital(fit, type = c("class", "prob"), prefix = "my_pred")

  preds <- predict(orb_obj, iris)

  expect_named(
    preds,
    c("my_pred_class", paste0("my_pred_", levels(iris$Species)))
  )
})

test_that("linear_reg(engine = 'glmnet') works with type = numeric", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("glmnet")

  spec <- parsnip::linear_reg(penalty = 0.01, engine = "glmnet")

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
    exps,
    tolerance = 0.0000001
  )
})
