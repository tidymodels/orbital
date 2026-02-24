test_that("rand_forest(engine = 'randomForest') works with type = numeric", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("randomForest")

  spec <- parsnip::rand_forest(
    mode = "regression",
    engine = "randomForest",
    trees = 10
  )

  set.seed(123)
  fit <- parsnip::fit(spec, mpg ~ disp + vs + hp, mtcars)

  orb_obj <- orbital(fit)

  # Avoid exact split values
  mtcars_test <- mtcars
  mtcars_test[, -which(names(mtcars) == "mpg")] <-
    mtcars_test[, -which(names(mtcars) == "mpg")] + 0.1

  preds <- predict(orb_obj, mtcars_test)
  exps <- predict(fit, mtcars_test)

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

test_that("rand_forest(engine = 'randomForest') works with type = class", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("randomForest")

  spec <- parsnip::rand_forest(
    mode = "classification",
    engine = "randomForest",
    trees = 10
  )

  set.seed(123)
  fit <- parsnip::fit(spec, Species ~ ., iris)

  orb_obj <- orbital(fit, type = "class")

  # Avoid exact split values
  iris_test <- iris
  iris_test[, -5] <- iris_test[, -5] + 0.1

  preds <- predict(orb_obj, iris_test)
  exps <- predict(fit, iris_test)

  expect_named(preds, ".pred_class")
  expect_type(preds$.pred_class, "character")

  expect_identical(
    preds$.pred_class,
    as.character(exps$.pred_class)
  )
})

test_that("rand_forest(engine = 'randomForest') works with type = prob", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("randomForest")

  spec <- parsnip::rand_forest(
    mode = "classification",
    engine = "randomForest",
    trees = 10
  )

  set.seed(123)
  fit <- parsnip::fit(spec, Species ~ ., iris)

  orb_obj <- orbital(fit, type = "prob")

  # Avoid exact split values
  iris_test <- iris
  iris_test[, -5] <- iris_test[, -5] + 0.1

  preds <- predict(orb_obj, iris_test)
  exps <- predict(fit, iris_test, type = "prob")

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

test_that("rand_forest(engine = 'randomForest') works with type = c(class, prob)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("randomForest")

  spec <- parsnip::rand_forest(
    mode = "classification",
    engine = "randomForest",
    trees = 10
  )

  set.seed(123)
  fit <- parsnip::fit(spec, Species ~ ., iris)

  orb_obj <- orbital(fit, type = c("class", "prob"))

  # Avoid exact split values
  iris_test <- iris
  iris_test[, -5] <- iris_test[, -5] + 0.1

  preds <- predict(orb_obj, iris_test)
  exps <- dplyr::bind_cols(
    predict(fit, iris_test, type = "class"),
    predict(fit, iris_test, type = "prob")
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

test_that("rand_forest(engine = 'randomForest') binary classification works", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("randomForest")

  mtcars$vs <- factor(mtcars$vs)

  spec <- parsnip::rand_forest(
    mode = "classification",
    engine = "randomForest",
    trees = 10
  )

  set.seed(123)
  fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)

  orb_obj <- orbital(fit, type = c("class", "prob"))

  # Avoid exact split values
  mtcars_test <- mtcars
  mtcars_test[, -8] <- mtcars_test[, -8] + 0.1

  preds <- predict(orb_obj, mtcars_test)
  exps <- dplyr::bind_cols(
    predict(fit, mtcars_test, type = "class"),
    predict(fit, mtcars_test, type = "prob")
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

test_that("rand_forest(engine = 'randomForest') works with custom prefix", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("randomForest")

  spec <- parsnip::rand_forest(
    mode = "classification",
    engine = "randomForest",
    trees = 5
  )

  set.seed(123)
  fit <- parsnip::fit(spec, Species ~ ., iris)

  orb_obj <- orbital(fit, type = c("class", "prob"), prefix = "my_pred")

  preds <- predict(orb_obj, iris)

  expect_named(
    preds,
    c("my_pred_class", paste0("my_pred_", levels(iris$Species)))
  )
})

