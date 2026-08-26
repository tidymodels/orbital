skip_if_no_xrf <- function(env = parent.frame()) {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("rules")
  skip_if_not_installed("xrf")
  # parsnip's xrf prediction module calls `xrf_pred()` unqualified, so `rules`
  # has to be attached rather than merely loaded for `predict()` to resolve it.
  withr::local_package("rules", .local_envir = env)
}

xrf_data <- function() {
  df <- iris[iris$Species != "setosa", ]
  df$Species <- droplevels(df$Species)
  df
}

test_that("rule_fit() works with type = numeric", {
  skip_if_no_xrf()

  set.seed(123)
  fit <- parsnip::fit(
    parsnip::rule_fit(mode = "regression", trees = 5, penalty = 0.01),
    Sepal.Length ~ .,
    iris[, -5]
  )

  preds <- predict(orbital(fit), iris)

  expect_named(preds, ".pred")
  expect_equal(preds$.pred, predict(fit, iris)$.pred, tolerance = 1e-8)
})

test_that("rule_fit() works with type = class and type = prob", {
  skip_if_no_xrf()

  df <- xrf_data()
  set.seed(123)
  fit <- parsnip::fit(
    parsnip::rule_fit(mode = "classification", trees = 5, penalty = 0.01),
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

test_that("rule_fit() refuses a multiclass outcome", {
  skip_if_no_xrf()

  # xrf itself only fits `family = "gaussian"` and `family = "binomial"`, so
  # there is nothing for orbital to translate. The refusal comes from upstream.
  set.seed(123)
  fit <- parsnip::fit(
    parsnip::rule_fit(mode = "classification", trees = 5, penalty = 0.01),
    Species ~ .,
    iris
  )

  expect_snapshot(error = TRUE, orbital(fit, type = "class"))
})

test_that("rule_fit() works with a custom prefix", {
  skip_if_no_xrf()

  df <- xrf_data()
  set.seed(123)
  fit <- parsnip::fit(
    parsnip::rule_fit(mode = "classification", trees = 5, penalty = 0.01),
    Species ~ .,
    df
  )

  preds <- predict(orbital(fit, type = "prob", prefix = "p"), df)

  expect_named(preds, c("p_versicolor", "p_virginica"))
})
