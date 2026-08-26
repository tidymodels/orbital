skip_if_no_kernlab <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("kernlab")
}

ksvm_data <- function(levels = c("versicolor", "virginica")) {
  df <- iris[iris$Species != "setosa", ]
  df$Species <- factor(as.character(df$Species), levels = levels)
  df
}

ksvm_fit <- function(data) {
  set.seed(123)
  parsnip::fit(
    parsnip::set_mode(
      parsnip::set_engine(parsnip::svm_linear(), "kernlab"),
      "classification"
    ),
    Species ~ .,
    data
  )
}

test_that("svm_linear() works with type = numeric", {
  skip_if_no_kernlab()

  set.seed(123)
  fit <- parsnip::fit(
    parsnip::set_mode(
      parsnip::set_engine(parsnip::svm_linear(), "kernlab"),
      "regression"
    ),
    Sepal.Length ~ .,
    iris[, -5]
  )

  preds <- predict(orbital(fit), iris)

  expect_named(preds, ".pred")
  expect_equal(preds$.pred, predict(fit, iris)$.pred, tolerance = 1e-8)
})

test_that("svm_linear() works with type = prob", {
  skip_if_no_kernlab()

  df <- ksvm_data()
  fit <- ksvm_fit(df)

  preds <- predict(orbital(fit, type = "prob"), df)

  expect_named(preds, c(".pred_versicolor", ".pred_virginica"))
  expect_equal(
    as.matrix(preds),
    as.matrix(predict(fit, df, type = "prob")),
    ignore_attr = TRUE
  )
})

test_that("svm_linear() works with type = class", {
  skip_if_no_kernlab()

  # kernlab classifies by the sign of the decision function and calibrates its
  # probabilities separately, so the class rule is not a 0.5 cut on them. Rows
  # near the boundary are the ones that tell the two cuts apart.
  df <- ksvm_data()
  fit <- ksvm_fit(df)

  expect_equal(
    predict(orbital(fit, type = "class"), df)$.pred_class,
    as.character(predict(fit, df)$.pred_class)
  )
})

test_that("svm_linear() class does not depend on the outcome's level order", {
  skip_if_no_kernlab()

  df <- ksvm_data(c("virginica", "versicolor"))
  fit <- ksvm_fit(df)

  expect_equal(
    predict(orbital(fit, type = "class"), df)$.pred_class,
    as.character(predict(fit, df)$.pred_class)
  )
})

test_that("svm_linear() works with a custom prefix", {
  skip_if_no_kernlab()

  df <- ksvm_data()
  fit <- ksvm_fit(df)

  preds <- predict(orbital(fit, type = "prob", prefix = "p"), df)

  expect_named(preds, c("p_versicolor", "p_virginica"))
})
