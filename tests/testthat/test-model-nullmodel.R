skip_if_no_parsnip <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
}

test_that("null_model() works with type = numeric", {
  skip_if_no_parsnip()

  fit <- parsnip::fit(
    parsnip::set_mode(parsnip::null_model(), "regression"),
    mpg ~ .,
    mtcars
  )

  preds <- predict(orbital(fit), mtcars)

  expect_named(preds, ".pred")
  # Every row gets the training mean, so the prediction does not vary.
  expect_equal(preds$.pred, predict(fit, mtcars)$.pred, ignore_attr = TRUE)
  expect_length(unique(preds$.pred), 1)
})

test_that("null_model() works with type = c(class, prob)", {
  skip_if_no_parsnip()

  fit <- parsnip::fit(
    parsnip::set_mode(parsnip::null_model(), "classification"),
    Species ~ .,
    iris
  )

  preds <- predict(orbital(fit, type = c("class", "prob")), iris)

  expect_named(
    preds,
    c(".pred_class", ".pred_setosa", ".pred_versicolor", ".pred_virginica")
  )
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
