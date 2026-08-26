skip_if_no_LiblineaR <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("LiblineaR")
}

two_species <- function(levels = c("versicolor", "virginica")) {
  df <- iris[iris$Species != "setosa", ]
  df$Species <- factor(as.character(df$Species), levels = levels)
  df
}

svm_fit <- function(data) {
  parsnip::fit(
    parsnip::set_mode(
      parsnip::set_engine(parsnip::svm_linear(), "LiblineaR"),
      "classification"
    ),
    Species ~ .,
    data
  )
}

test_that("svm_linear() works with type = class", {
  skip_if_no_LiblineaR()

  df <- two_species()
  fit <- svm_fit(df)

  expect_equal(
    predict(orbital(fit, type = "class"), df)$.pred_class,
    as.character(predict(fit, df)$.pred_class)
  )
})

test_that("svm_linear() class does not depend on the outcome's level order", {
  skip_if_no_LiblineaR()

  # LiblineaR orients its decision value by its own class order, so a positive
  # value does not always mean the second level. Reversing the levels here
  # leaves `ClassNames` alone, which is what pulls the two apart.
  df <- two_species(c("virginica", "versicolor"))
  fit <- svm_fit(df)

  expect_equal(
    predict(orbital(fit, type = "class"), df)$.pred_class,
    as.character(predict(fit, df)$.pred_class)
  )
})

test_that("svm_linear() works with type = numeric", {
  skip_if_no_LiblineaR()

  fit <- parsnip::fit(
    parsnip::set_mode(
      parsnip::set_engine(parsnip::svm_linear(), "LiblineaR"),
      "regression"
    ),
    Sepal.Length ~ .,
    iris[, -5]
  )

  preds <- predict(orbital(fit), iris)

  expect_named(preds, ".pred")
  expect_equal(preds$.pred, predict(fit, iris)$.pred, tolerance = 1e-8)
})

test_that("logistic_reg() works with type = class and type = prob", {
  skip_if_no_LiblineaR()

  df <- two_species()
  fit <- parsnip::fit(
    parsnip::set_engine(parsnip::logistic_reg(), "LiblineaR"),
    Species ~ .,
    df
  )

  expect_equal(
    predict(orbital(fit, type = "class"), df)$.pred_class,
    as.character(predict(fit, df)$.pred_class)
  )
  expect_equal(
    as.matrix(predict(orbital(fit, type = "prob"), df)),
    as.matrix(predict(fit, df, type = "prob")),
    ignore_attr = TRUE
  )
})

test_that("logistic_reg() works with a custom prefix", {
  skip_if_no_LiblineaR()

  df <- two_species()
  fit <- parsnip::fit(
    parsnip::set_engine(parsnip::logistic_reg(), "LiblineaR"),
    Species ~ .,
    df
  )

  preds <- predict(orbital(fit, type = "prob", prefix = "p"), df)

  expect_named(preds, c("p_versicolor", "p_virginica"))
})
