skip_if_no_C50 <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("C50")
}

binary_iris <- function() {
  droplevels(iris[iris$Species != "setosa", ])
}

test_that("boost_tree(C5.0) works with type = class for binary outcomes", {
  skip_if_no_C50()

  data <- binary_iris()
  spec <- parsnip::boost_tree(
    trees = 1,
    mode = "classification",
    engine = "C5.0"
  )
  fit <- parsnip::fit(spec, Species ~ ., data)

  preds <- predict(orbital(fit, type = "class"), data)

  expect_named(preds, ".pred_class")
  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, data)$.pred_class)
  )
})

test_that("boost_tree(C5.0) works with type = class for multiclass outcomes", {
  skip_if_no_C50()

  spec <- parsnip::boost_tree(
    trees = 1,
    mode = "classification",
    engine = "C5.0"
  )
  fit <- parsnip::fit(spec, Species ~ ., iris)

  preds <- predict(orbital(fit, type = "class"), iris)

  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, iris)$.pred_class)
  )
})

test_that("boost_tree(C5.0) works with more than one boosting round", {
  skip_if_no_C50()

  # Boosting combines the trees by confidence-weighted vote rather than by a
  # plain majority, so a multi-trial fit exercises a different code path in
  # tidypredict than the single-tree case above.
  spec <- parsnip::boost_tree(
    trees = 5,
    mode = "classification",
    engine = "C5.0"
  )
  fit <- parsnip::fit(spec, Species ~ ., iris)

  preds <- predict(orbital(fit, type = "class"), iris)

  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, iris)$.pred_class)
  )
})

test_that("decision_tree(C5.0) works with type = class", {
  skip_if_no_C50()

  spec <- parsnip::decision_tree(mode = "classification", engine = "C5.0")
  fit <- parsnip::fit(spec, Species ~ ., iris)

  preds <- predict(orbital(fit, type = "class"), iris)

  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, iris)$.pred_class)
  )
})

test_that("decision_tree(C5.0) errors for type = prob", {
  skip_if_no_C50()

  spec <- parsnip::decision_tree(mode = "classification", engine = "C5.0")
  fit <- parsnip::fit(spec, Species ~ ., iris)

  expect_snapshot(error = TRUE, orbital(fit, type = "prob"))
})

test_that("C5_rules() works with type = class", {
  skip_if_no_C50()
  skip_if_not_installed("rules")

  spec <- parsnip::set_engine(parsnip::C5_rules(trees = 1), "C5.0")
  fit <- parsnip::fit(spec, Species ~ ., iris)

  preds <- predict(orbital(fit, type = "class"), iris)

  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, iris)$.pred_class)
  )
})

test_that("boost_tree(C5.0) works with custom prefix", {
  skip_if_no_C50()

  spec <- parsnip::boost_tree(
    trees = 1,
    mode = "classification",
    engine = "C5.0"
  )
  fit <- parsnip::fit(spec, Species ~ ., iris)

  preds <- predict(orbital(fit, type = "class", prefix = "my_pred"), iris)

  expect_named(preds, "my_pred_class")
})

test_that("boost_tree(C5.0) errors for type = prob", {
  skip_if_no_C50()

  spec <- parsnip::boost_tree(
    trees = 1,
    mode = "classification",
    engine = "C5.0"
  )
  fit <- parsnip::fit(spec, Species ~ ., iris)

  expect_snapshot(error = TRUE, orbital(fit, type = "prob"))
})
