skip_if_no_nnet <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("nnet")
}

multinom_fit <- function(data = iris) {
  parsnip::fit(
    parsnip::set_engine(parsnip::multinom_reg(penalty = 0), "nnet"),
    Species ~ .,
    data
  )
}

mlp_fit <- function(mode, formula, data) {
  set.seed(1)
  suppressWarnings(parsnip::fit(
    parsnip::set_mode(
      parsnip::set_engine(parsnip::mlp(epochs = 20), "nnet"),
      mode
    ),
    formula,
    data
  ))
}

test_that("multinom_reg() works with type = prob", {
  skip_if_no_nnet()

  fit <- multinom_fit()
  preds <- predict(orbital(fit, type = "prob"), iris)

  expect_named(preds, c(".pred_setosa", ".pred_versicolor", ".pred_virginica"))
  expect_equal(
    as.matrix(preds),
    as.matrix(predict(fit, iris, type = "prob")),
    ignore_attr = TRUE
  )
})

test_that("multinom_reg() works with type = c(class, prob)", {
  skip_if_no_nnet()

  fit <- multinom_fit()
  preds <- predict(orbital(fit, type = c("class", "prob")), iris)

  expect_named(
    preds,
    c(".pred_class", ".pred_setosa", ".pred_versicolor", ".pred_virginica")
  )
  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, iris)$.pred_class)
  )
})

test_that("mlp() works with type = numeric", {
  skip_if_no_nnet()

  fit <- mlp_fit("regression", mpg ~ disp + hp, mtcars)
  preds <- predict(orbital(fit), mtcars)

  expect_named(preds, ".pred")
  expect_equal(preds$.pred, predict(fit, mtcars)$.pred, ignore_attr = TRUE)
})

test_that("mlp() works with type = c(class, prob)", {
  skip_if_no_nnet()

  fit <- mlp_fit("classification", Species ~ ., iris)
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

test_that("mlp() binary classification works", {
  skip_if_no_nnet()

  data <- mtcars
  data$vs <- factor(data$vs)

  fit <- mlp_fit("classification", vs ~ disp + hp, data)
  preds <- predict(orbital(fit, type = c("class", "prob")), data)

  expect_named(preds, c(".pred_class", ".pred_0", ".pred_1"))
  expect_equal(
    as.matrix(preds[, -1]),
    as.matrix(predict(fit, data, type = "prob")),
    ignore_attr = TRUE
  )
})
