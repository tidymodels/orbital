skip_if_no_discrim <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("discrim")
  skip_if_not_installed("MASS")
}

lda_fit <- function(data = iris) {
  parsnip::fit(
    parsnip::set_engine(parsnip::discrim_linear(), "MASS"),
    Species ~ .,
    data
  )
}

qda_fit <- function(data = iris) {
  parsnip::fit(
    parsnip::set_engine(parsnip::discrim_quad(), "MASS"),
    Species ~ .,
    data
  )
}

test_that("discrim_linear() works with type = prob", {
  skip_if_no_discrim()

  fit <- lda_fit()
  preds <- predict(orbital(fit, type = "prob"), iris)

  expect_named(preds, c(".pred_setosa", ".pred_versicolor", ".pred_virginica"))
  expect_equal(
    as.matrix(preds),
    as.matrix(predict(fit, iris, type = "prob")),
    ignore_attr = TRUE
  )
})

test_that("discrim_linear() works with type = class", {
  skip_if_no_discrim()

  fit <- lda_fit()
  preds <- predict(orbital(fit, type = "class"), iris)

  expect_named(preds, ".pred_class")
  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, iris)$.pred_class)
  )
})

test_that("discrim_linear() works with type = c(class, prob)", {
  skip_if_no_discrim()

  fit <- lda_fit()
  preds <- predict(orbital(fit, type = c("class", "prob")), iris)

  expect_named(
    preds,
    c(".pred_class", ".pred_setosa", ".pred_versicolor", ".pred_virginica")
  )
})

test_that("discrim_linear() probabilities follow the outcome's level order", {
  skip_if_no_discrim()

  # tidypredict returns the per-level expressions in model order. Reversing the
  # levels makes that disagree with the order parsnip recorded, so a positional
  # pass-through would label every column wrongly while still looking plausible.
  data <- iris
  data$Species <- factor(data$Species, levels = rev(levels(data$Species)))

  fit <- lda_fit(data)
  preds <- predict(orbital(fit, type = "prob"), data)

  expect_named(preds, c(".pred_virginica", ".pred_versicolor", ".pred_setosa"))
  expect_equal(
    as.matrix(preds),
    as.matrix(predict(fit, data, type = "prob")),
    ignore_attr = TRUE
  )
})

test_that("discrim_quad() works with type = c(class, prob)", {
  skip_if_no_discrim()

  fit <- qda_fit()
  preds <- predict(orbital(fit, type = c("class", "prob")), iris)

  expect_equal(
    as.matrix(preds[, -1]),
    as.matrix(predict(fit, iris, type = "prob")),
    ignore_attr = TRUE
  )
  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, iris)$.pred_class)
  )
})

test_that("discrim_linear() works with a custom prefix", {
  skip_if_no_discrim()

  fit <- lda_fit()
  preds <- predict(orbital(fit, type = c("class", "prob"), prefix = "p"), iris)

  expect_named(preds, c("p_class", "p_setosa", "p_versicolor", "p_virginica"))
})
