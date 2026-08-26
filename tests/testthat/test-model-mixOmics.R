skip_if_no_mixOmics <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("plsmod")
  skip_if_not_installed("mixOmics")
}

test_that("pls() works with type = numeric", {
  skip_if_no_mixOmics()

  fit <- parsnip::fit(
    parsnip::pls(num_comp = 2, mode = "regression"),
    Sepal.Length ~ .,
    iris[, -5]
  )

  preds <- predict(orbital(fit), iris)

  expect_named(preds, ".pred")
  expect_equal(preds$.pred, predict(fit, iris)$.pred, tolerance = 1e-8)
})

test_that("pls() works with type = prob", {
  skip_if_no_mixOmics()

  fit <- parsnip::fit(
    parsnip::pls(num_comp = 2, mode = "classification"),
    Species ~ .,
    iris
  )

  preds <- predict(orbital(fit, type = "prob"), iris)

  expect_named(preds, c(".pred_setosa", ".pred_versicolor", ".pred_virginica"))
  expect_equal(
    as.matrix(preds),
    as.matrix(predict(fit, iris, type = "prob")),
    ignore_attr = TRUE
  )
})

test_that("pls() refuses type = class", {
  skip_if_no_mixOmics()

  # mixOmics assigns a class by distance to the class centroid in the latent
  # space, which disagrees with the largest per-level value on a fifth of these
  # rows. Returning the argmax would be a confident wrong answer.
  fit <- parsnip::fit(
    parsnip::pls(num_comp = 2, mode = "classification"),
    Species ~ .,
    iris
  )

  expect_snapshot(error = TRUE, orbital(fit, type = "class"))
})

test_that("pls() works with a custom prefix", {
  skip_if_no_mixOmics()

  fit <- parsnip::fit(
    parsnip::pls(num_comp = 2, mode = "classification"),
    Species ~ .,
    iris
  )

  preds <- predict(orbital(fit, type = "prob", prefix = "p"), iris)

  expect_named(preds, c("p_setosa", "p_versicolor", "p_virginica"))
})
