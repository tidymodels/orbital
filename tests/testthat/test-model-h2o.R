h2o_two_species <- function(levels = c("versicolor", "virginica")) {
  df <- iris[iris$Species != "setosa", ]
  df$Species <- factor(as.character(df$Species), levels = levels)
  df
}

# h2o picks a threshold that maximizes F1, and that threshold is one of the
# probabilities it actually predicted. A row landing exactly on it is decided by
# arithmetic orbital cannot reproduce bit for bit, since it recomputes the
# probability from the translated expression. Such rows are excluded rather than
# asserted on; everything either side of the threshold is exact.
expect_class_agreement <- function(fit, data) {
  orb <- as.character(predict(orbital(fit, type = "class"), data)[[1]])
  own <- as.character(predict(fit, data, type = "class")$.pred_class)

  threshold <- fit$fit@model$default_threshold
  probs <- predict(fit, data, type = "prob")
  decided <- abs(probs[[2]] - threshold) > 1e-9

  expect_equal(orb[decided], own[decided])
}

test_that("boost_tree() works with type = numeric", {
  skip_if_no_h2o()

  fit <- parsnip::fit(
    parsnip::boost_tree(mode = "regression", engine = "h2o_gbm", trees = 5),
    Sepal.Length ~ .,
    iris[, -5]
  )

  preds <- predict(orbital(fit), iris)

  expect_named(preds, ".pred")
  expect_equal(preds$.pred, predict(fit, iris)$.pred, tolerance = 1e-6)
})

test_that("boost_tree() works with type = class and type = prob", {
  skip_if_no_h2o()

  df <- h2o_two_species()
  fit <- parsnip::fit(
    parsnip::boost_tree(mode = "classification", engine = "h2o_gbm", trees = 5),
    Species ~ .,
    df
  )

  expect_class_agreement(fit, df)

  preds <- predict(orbital(fit, type = "prob"), df)
  expect_named(preds, c(".pred_versicolor", ".pred_virginica"))
  expect_equal(
    as.matrix(preds),
    as.matrix(predict(fit, df, type = "prob")),
    ignore_attr = TRUE,
    tolerance = 1e-6
  )
})

test_that("boost_tree() binary does not depend on the outcome's level order", {
  skip_if_no_h2o()

  # h2o sorts its own class domain and keeps that order however the outcome's
  # factor levels are ordered, so the single probability it returns is not
  # always the one for the second level, and its threshold applies to whichever
  # level it did return.
  df <- h2o_two_species(c("virginica", "versicolor"))
  fit <- parsnip::fit(
    parsnip::boost_tree(mode = "classification", engine = "h2o_gbm", trees = 5),
    Species ~ .,
    df
  )

  expect_class_agreement(fit, df)

  preds <- predict(orbital(fit, type = "prob"), df)
  expect_named(preds, c(".pred_virginica", ".pred_versicolor"))
  expect_equal(
    preds$.pred_virginica,
    predict(fit, df, type = "prob")$.pred_virginica,
    tolerance = 1e-6
  )
})

test_that("boost_tree() works with a multiclass outcome", {
  skip_if_no_h2o()

  fit <- parsnip::fit(
    parsnip::boost_tree(mode = "classification", engine = "h2o_gbm", trees = 5),
    Species ~ .,
    iris
  )

  expect_equal(
    predict(orbital(fit, type = "class"), iris)$.pred_class,
    as.character(predict(fit, iris, type = "class")$.pred_class)
  )
  expect_equal(
    as.matrix(predict(orbital(fit, type = "prob"), iris)),
    as.matrix(predict(fit, iris, type = "prob")),
    ignore_attr = TRUE,
    tolerance = 1e-6
  )
})

test_that("rule_fit() works with type = numeric", {
  skip_if_no_h2o()

  fit <- parsnip::fit(
    parsnip::rule_fit(mode = "regression", engine = "h2o", trees = 5),
    Sepal.Length ~ .,
    iris[, -5]
  )

  preds <- predict(orbital(fit), iris)

  expect_named(preds, ".pred")
  expect_equal(preds$.pred, predict(fit, iris)$.pred, tolerance = 1e-6)
})

test_that("rule_fit() works with type = class and type = prob", {
  skip_if_no_h2o()

  df <- h2o_two_species()
  fit <- parsnip::fit(
    parsnip::rule_fit(mode = "classification", engine = "h2o", trees = 5),
    Species ~ .,
    df
  )

  expect_class_agreement(fit, df)
  expect_equal(
    as.matrix(predict(orbital(fit, type = "prob"), df)),
    as.matrix(predict(fit, df, type = "prob")),
    ignore_attr = TRUE,
    tolerance = 1e-6
  )
})

test_that("h2o models work with a custom prefix", {
  skip_if_no_h2o()

  df <- h2o_two_species()
  fit <- parsnip::fit(
    parsnip::boost_tree(mode = "classification", engine = "h2o_gbm", trees = 5),
    Species ~ .,
    df
  )

  preds <- predict(orbital(fit, type = "prob", prefix = "p"), df)

  expect_named(preds, c("p_versicolor", "p_virginica"))
})

test_that("an unsupported h2o model is refused", {
  skip_if_no_h2o()

  # tidypredict translates h2o GBM and RuleFit only.
  fit <- parsnip::fit(
    parsnip::linear_reg(engine = "h2o"),
    Sepal.Length ~ .,
    iris[, -5]
  )

  expect_snapshot(error = TRUE, orbital(fit))
})
