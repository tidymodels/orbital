test_that("mars(engine = 'earth') works with type = numeric", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("earth")

  spec <- parsnip::mars(mode = "regression", engine = "earth")

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

test_that("mars(engine = 'earth') works with type = class", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("earth")

  mtcars$vs <- factor(mtcars$vs)

  spec <- parsnip::mars(mode = "classification", engine = "earth")

  suppressWarnings(
    fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)
  )

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

test_that("mars(engine = 'earth') works with type = prob", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("earth")

  mtcars$vs <- factor(mtcars$vs)

  spec <- parsnip::mars(mode = "classification", engine = "earth")

  suppressWarnings(
    fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)
  )

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

test_that("mars(engine = 'earth') works with type = c(class, prob)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("earth")

  mtcars$vs <- factor(mtcars$vs)

  spec <- parsnip::mars(mode = "classification", engine = "earth")

  suppressWarnings(
    fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)
  )

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

test_that("mars(engine = 'earth') works with custom prefix", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("earth")

  mtcars$vs <- factor(mtcars$vs)

  spec <- parsnip::mars(mode = "classification", engine = "earth")

  suppressWarnings(
    fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)
  )

  orb_obj <- orbital(fit, type = c("class", "prob"), prefix = "my_pred")

  preds <- predict(orb_obj, mtcars)

  expect_named(preds, c("my_pred_class", "my_pred_0", "my_pred_1"))
})

# Multiclass earth tests
# Note: These tests compare against raw earth predictions (fit$fit) rather than
# parsnip predictions because parsnip has a bug with multiclass earth models
# that returns incorrect probabilities and missing columns. The raw earth model
# predictions are correct. See: https://github.com/tidymodels/parsnip/issues/1334

test_that("mars(engine = 'earth') multiclass works with type = class", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("earth")

  spec <- parsnip::mars(mode = "classification", engine = "earth")

  set.seed(123)
  suppressWarnings(
    fit <- parsnip::fit(spec, Species ~ ., iris)
  )

  orb_obj <- orbital(fit, type = "class")

  preds <- predict(orb_obj, iris)

  # Get expected classes from raw earth predictions
  raw_probs <- predict(fit$fit, iris, type = "response")
  exps_class <- colnames(raw_probs)[max.col(raw_probs, ties.method = "first")]

  expect_named(preds, ".pred_class")
  expect_type(preds$.pred_class, "character")

  expect_identical(
    preds$.pred_class,
    exps_class
  )
})

test_that("mars(engine = 'earth') multiclass works with type = prob", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("earth")

  spec <- parsnip::mars(mode = "classification", engine = "earth")

  set.seed(123)
  suppressWarnings(
    fit <- parsnip::fit(spec, Species ~ ., iris)
  )

  orb_obj <- orbital(fit, type = "prob")

  preds <- predict(orb_obj, iris)

  # Get expected probabilities from raw earth predictions
  raw_probs <- predict(fit$fit, iris, type = "response")
  # Apply softmax to convert logits to probabilities
  exp_probs <- exp(raw_probs)
  exp_probs <- exp_probs / rowSums(exp_probs)
  exps <- as.data.frame(exp_probs)
  names(exps) <- paste0(".pred_", levels(iris$Species))

  expect_named(preds, paste0(".pred_", levels(iris$Species)))
  expect_type(preds$.pred_setosa, "double")
  expect_type(preds$.pred_versicolor, "double")
  expect_type(preds$.pred_virginica, "double")

  rownames(preds) <- NULL
  rownames(exps) <- NULL

  expect_equal(
    preds,
    exps,
    tolerance = 0.0000001
  )
})

test_that("mars(engine = 'earth') multiclass works with type = c(class, prob)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("earth")

  spec <- parsnip::mars(mode = "classification", engine = "earth")

  set.seed(123)
  suppressWarnings(
    fit <- parsnip::fit(spec, Species ~ ., iris)
  )

  orb_obj <- orbital(fit, type = c("class", "prob"))

  preds <- predict(orb_obj, iris)

  # Get expected values from raw earth predictions
  raw_probs <- predict(fit$fit, iris, type = "response")
  exp_class <- colnames(raw_probs)[max.col(raw_probs, ties.method = "first")]
  # Apply softmax to convert logits to probabilities
  exp_probs <- exp(raw_probs)
  exp_probs <- exp_probs / rowSums(exp_probs)

  exps <- as.data.frame(exp_probs)
  names(exps) <- paste0(".pred_", levels(iris$Species))
  exps <- cbind(data.frame(.pred_class = exp_class), exps)

  expect_named(preds, c(".pred_class", paste0(".pred_", levels(iris$Species))))
  expect_type(preds$.pred_class, "character")
  expect_type(preds$.pred_setosa, "double")
  expect_type(preds$.pred_versicolor, "double")
  expect_type(preds$.pred_virginica, "double")

  rownames(preds) <- NULL
  rownames(exps) <- NULL

  expect_equal(
    preds,
    exps,
    tolerance = 0.0000001
  )
})

test_that("mars(engine = 'earth') multiclass works with custom prefix", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("earth")

  spec <- parsnip::mars(mode = "classification", engine = "earth")

  set.seed(123)
  suppressWarnings(
    fit <- parsnip::fit(spec, Species ~ ., iris)
  )

  orb_obj <- orbital(fit, type = c("class", "prob"), prefix = "my_pred")

  preds <- predict(orb_obj, iris)

  expect_named(
    preds,
    c("my_pred_class", paste0("my_pred_", levels(iris$Species)))
  )
})
