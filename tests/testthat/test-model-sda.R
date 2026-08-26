skip_if_no_sda <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("discrim")
  skip_if_not_installed("sda")
}

sda_fit <- function(data = iris) {
  parsnip::fit(
    parsnip::set_engine(parsnip::discrim_linear(), "sda"),
    Species ~ .,
    data
  )
}

test_that("discrim_linear(sda) works with type = prob", {
  skip_if_no_sda()

  fit <- sda_fit()
  preds <- predict(orbital(fit, type = "prob"), iris)

  expect_named(preds, c(".pred_setosa", ".pred_versicolor", ".pred_virginica"))
  expect_equal(
    as.matrix(preds),
    as.matrix(predict(fit, iris, type = "prob")),
    ignore_attr = TRUE,
    tolerance = 1e-6
  )
})

test_that("discrim_linear(sda) works with type = class", {
  skip_if_no_sda()

  fit <- sda_fit()
  preds <- predict(orbital(fit, type = "class"), iris)

  expect_named(preds, ".pred_class")
  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, iris)$.pred_class)
  )
})

test_that("discrim_linear(sda) probabilities follow the outcome's level order", {
  skip_if_no_sda()

  data <- iris
  data$Species <- factor(data$Species, levels = rev(levels(data$Species)))

  fit <- sda_fit(data)
  preds <- predict(orbital(fit, type = "prob"), data)

  expect_named(preds, c(".pred_virginica", ".pred_versicolor", ".pred_setosa"))
  expect_equal(
    as.matrix(preds),
    as.matrix(predict(fit, data, type = "prob")),
    ignore_attr = TRUE,
    tolerance = 1e-6
  )
})

test_that("discrim_linear(sda) works with a custom prefix", {
  skip_if_no_sda()

  fit <- sda_fit()
  preds <- predict(orbital(fit, type = c("class", "prob"), prefix = "p"), iris)

  expect_named(preds, c("p_class", "p_setosa", "p_versicolor", "p_virginica"))
})
