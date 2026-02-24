test_that("boost_tree(engine = 'lightgbm'), objective = regression, works with type = numeric", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  bt_spec <- parsnip::boost_tree(
    mode = "regression",
    engine = "lightgbm",
    min_n = 1
  )

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

test_that("boost_tree(engine = 'lightgbm'), objective = binary, works with type = class", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  mtcars$vs <- factor(mtcars$vs)

  bt_spec <- parsnip::boost_tree(
    mode = "classification",
    engine = "lightgbm",
    min_n = 1
  )

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

test_that("boost_tree(engine = 'lightgbm'), objective = binary, works with type = prob", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  mtcars$vs <- factor(mtcars$vs)

  bt_spec <- parsnip::boost_tree(
    mode = "classification",
    engine = "lightgbm",
    min_n = 1
  )

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

test_that("boost_tree(engine = 'lightgbm'), objective = binary, works with type = c(class, prob)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  mtcars$vs <- factor(mtcars$vs)

  bt_spec <- parsnip::boost_tree(
    mode = "classification",
    engine = "lightgbm",
    min_n = 1
  )

  bt_fit <- parsnip::fit(bt_spec, vs ~ disp + mpg + hp, mtcars)

  orb_obj <- orbital(bt_fit, type = c("class", "prob"))

  # to avoid exact split values
  mtcars[, -8] <- mtcars[, -8] + 0.1

  preds <- predict(orb_obj, mtcars)
  exps <- dplyr::bind_cols(
    predict(bt_fit, mtcars, type = "class"),
    predict(bt_fit, mtcars, type = "prob")
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

test_that("boost_tree(engine = 'lightgbm'), objective = multiclass, works with type = class", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  bt_spec <- parsnip::boost_tree(
    mode = "classification",
    engine = "lightgbm",
    min_n = 1
  )

  bt_fit <- parsnip::fit(bt_spec, Species ~ ., iris)

  orb_obj <- orbital(bt_fit, type = "class")

  # Use larger offset (0.07) to avoid floating-point precision issues at
  # decision boundaries that can occur with lightgbm's tree split values
  iris[, -5] <- iris[, -5] + 0.07

  preds <- predict(orb_obj, iris)
  exps <- predict(bt_fit, iris)

  expect_named(preds, ".pred_class")
  expect_type(preds$.pred_class, "character")

  expect_identical(
    preds$.pred_class,
    as.character(exps$.pred_class)
  )
})

test_that("boost_tree(engine = 'lightgbm'), objective = multiclass, works with type = prob", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  bt_spec <- parsnip::boost_tree(
    mode = "classification",
    engine = "lightgbm",
    min_n = 1
  )

  bt_fit <- parsnip::fit(bt_spec, Species ~ ., iris)

  orb_obj <- orbital(bt_fit, type = "prob")

  # Use larger offset to avoid floating-point precision issues
  iris[, -5] <- iris[, -5] + 0.07

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

test_that("boost_tree(engine = 'lightgbm'), objective = multiclass, works with type = c(class, prob)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  bt_spec <- parsnip::boost_tree(
    mode = "classification",
    engine = "lightgbm",
    min_n = 1
  )

  bt_fit <- parsnip::fit(bt_spec, Species ~ ., iris)

  orb_obj <- orbital(bt_fit, type = c("class", "prob"))

  # Use larger offset to avoid floating-point precision issues
  iris[, -5] <- iris[, -5] + 0.07

  preds <- predict(orb_obj, iris)
  exps <- dplyr::bind_cols(
    predict(bt_fit, iris, type = "class"),
    predict(bt_fit, iris, type = "prob")
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

test_that("boost_tree(lightgbm) works with custom prefix", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  bt_spec <- parsnip::boost_tree(
    mode = "regression",
    engine = "lightgbm",
    min_n = 1
  )

  bt_fit <- parsnip::fit(bt_spec, mpg ~ disp + vs + hp, mtcars)

  orb_obj <- orbital(bt_fit, prefix = "my_pred")

  preds <- predict(orb_obj, mtcars)

  expect_named(preds, "my_pred")
})

test_that("boost_tree(lightgbm) regression works with separate_trees = TRUE", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  bt_spec <- parsnip::boost_tree(
    mode = "regression",
    engine = "lightgbm",
    trees = 5,
    min_n = 1
  )
  bt_fit <- parsnip::fit(bt_spec, mpg ~ disp + hp, mtcars)

  orb_collapsed <- orbital(bt_fit, separate_trees = FALSE)
  orb_split <- orbital(bt_fit, separate_trees = TRUE)

  expect_length(orb_collapsed, 1)
  expect_gt(length(orb_split), 1)
  expect_match(names(orb_split), "_tree_", all = FALSE)

  mtcars2 <- mtcars + 0.1
  preds_collapsed <- predict(orb_collapsed, mtcars2)
  preds_split <- predict(orb_split, mtcars2)

  expect_named(preds_split, ".pred")
  expect_equal(preds_collapsed, preds_split, tolerance = 1e-10)
})

test_that("boost_tree(lightgbm) binary classification works with separate_trees = TRUE", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  mtcars2 <- mtcars
  mtcars2$vs <- factor(mtcars2$vs)

  bt_spec <- parsnip::boost_tree(
    mode = "classification",
    engine = "lightgbm",
    trees = 5,
    min_n = 1
  )
  bt_fit <- parsnip::fit(bt_spec, vs ~ disp + hp, mtcars2)

  orb_collapsed <- orbital(
    bt_fit,
    type = c("class", "prob"),
    separate_trees = FALSE
  )
  orb_split <- orbital(bt_fit, type = c("class", "prob"), separate_trees = TRUE)

  expect_lt(length(orb_collapsed), length(orb_split))
  expect_match(names(orb_split), "_tree_", all = FALSE)

  mtcars2[, -8] <- mtcars2[, -8] + 0.1
  preds_collapsed <- predict(orb_collapsed, mtcars2)
  preds_split <- predict(orb_split, mtcars2)

  expect_named(preds_split, c(".pred_class", ".pred_0", ".pred_1"))
  expect_equal(preds_collapsed, preds_split, tolerance = 1e-10)
})

test_that("boost_tree(lightgbm) multiclass works with separate_trees = TRUE", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  bt_spec <- parsnip::boost_tree(
    mode = "classification",
    engine = "lightgbm",
    trees = 3,
    min_n = 1
  )
  bt_fit <- parsnip::fit(bt_spec, Species ~ ., iris)

  orb_collapsed <- orbital(
    bt_fit,
    type = c("class", "prob"),
    separate_trees = FALSE
  )
  orb_split <- orbital(bt_fit, type = c("class", "prob"), separate_trees = TRUE)

  expect_lt(length(orb_collapsed), length(orb_split))
  expect_match(names(orb_split), "_tree_", all = FALSE)

  iris2 <- iris
  iris2[, -5] <- iris2[, -5] + 0.05
  preds_collapsed <- predict(orb_collapsed, iris2)
  preds_split <- predict(orb_split, iris2)

  expect_named(
    preds_split,
    c(".pred_class", paste0(".pred_", levels(iris$Species)))
  )
  expect_equal(preds_collapsed, preds_split, tolerance = 1e-10)
})

test_that("separate_trees batches summation for many trees (lightgbm multiclass)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  bt_spec <- parsnip::boost_tree(
    mode = "classification",
    engine = "lightgbm",
    trees = 120,
    min_n = 1
  )
  bt_fit <- parsnip::fit(bt_spec, Species ~ ., iris)

  orb <- orbital(bt_fit, type = "prob", separate_trees = TRUE)

  # Each class should have trees, batched in groups of 50
  n_class_trees <- sum(grepl("_logit_tree_", names(orb)))
  n_class_batch <- sum(grepl("_logit_sum_", names(orb)))

  expect_gt(n_class_trees, 100)
  expect_gt(n_class_batch, 0)

  preds <- predict(orb, iris)
  expect_named(preds, paste0(".pred_", levels(iris$Species)))
})
