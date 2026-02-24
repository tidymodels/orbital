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

test_that("rand_forest(randomForest) regression works with separate_trees = TRUE", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("randomForest")

  spec <- parsnip::rand_forest(
    mode = "regression",
    engine = "randomForest",
    trees = 5
  )

  set.seed(123)
  fit <- parsnip::fit(spec, mpg ~ disp + hp, mtcars)

  orb_collapsed <- orbital(fit, separate_trees = FALSE)
  orb_split <- orbital(fit, separate_trees = TRUE)

  expect_length(orb_collapsed, 1)
  expect_gt(length(orb_split), 1)
  expect_match(names(orb_split), "_tree_", all = FALSE)

  preds_collapsed <- predict(orb_collapsed, mtcars)
  preds_split <- predict(orb_split, mtcars)

  expect_named(preds_split, ".pred")
  expect_equal(preds_collapsed, preds_split, tolerance = 1e-10)
})

test_that("rand_forest(randomForest) classification works with separate_trees = TRUE", {
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

  orb_collapsed <- orbital(
    fit,
    type = c("class", "prob"),
    separate_trees = FALSE
  )
  orb_split <- orbital(fit, type = c("class", "prob"), separate_trees = TRUE)

  expect_lt(length(orb_collapsed), length(orb_split))
  expect_match(names(orb_split), "_tree_", all = FALSE)

  preds_collapsed <- predict(orb_collapsed, iris)
  preds_split <- predict(orb_split, iris)

  expect_named(
    preds_split,
    c(".pred_class", paste0(".pred_", levels(iris$Species)))
  )
  expect_equal(preds_collapsed, preds_split, tolerance = 1e-10)
})

test_that("separate_trees batches summation for many trees (randomForest regression)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("randomForest")

  spec <- parsnip::rand_forest(
    mode = "regression",
    engine = "randomForest",
    trees = 120
  )

  set.seed(123)
  fit <- parsnip::fit(spec, mpg ~ disp + hp, mtcars)

  orb <- orbital(fit, separate_trees = TRUE)

  # 120 trees + 3 batch sums + 1 final = 124
  expect_length(orb, 124)
  expect_equal(sum(grepl("_tree_", names(orb))), 120)
  expect_equal(sum(grepl("_sum_", names(orb))), 3)

  preds <- predict(orb, mtcars)
  expect_named(preds, ".pred")
})

test_that("separate_trees batches summation for many trees (randomForest classification)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("randomForest")

  spec <- parsnip::rand_forest(
    mode = "classification",
    engine = "randomForest",
    trees = 120
  )

  set.seed(123)
  fit <- parsnip::fit(spec, Species ~ ., iris)

  orb <- orbital(fit, type = "prob", separate_trees = TRUE)

  # Each class has 120 trees, batched in groups of 50
  # Pattern: .pred_{class}_votes_tree_N for trees
  # Pattern: .pred_{class}_votes_sum_N for batch sums
  n_class_trees <- sum(grepl("_votes_tree_", names(orb)))
  n_class_batch <- sum(grepl("_votes_sum_", names(orb)))

  expect_equal(n_class_trees, 360) # 120 trees * 3 classes
  expect_equal(n_class_batch, 9) # 3 batch sums * 3 classes

  preds <- predict(orb, iris)
  expect_named(preds, paste0(".pred_", levels(iris$Species)))
})
