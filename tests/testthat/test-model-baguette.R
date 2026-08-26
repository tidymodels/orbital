skip_if_no_baguette <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("baguette")
}

test_that("bag_tree(rpart) works with type = class for binary outcomes", {
  skip_if_no_baguette()
  skip_if_not_installed("rpart")

  data <- droplevels(iris[iris$Species != "setosa", ])
  spec <- parsnip::set_engine(
    parsnip::set_mode(parsnip::bag_tree(), "classification"),
    "rpart"
  )
  fit <- parsnip::fit(spec, Species ~ ., data)

  preds <- predict(orbital(fit, type = "class"), data)

  expect_named(preds, ".pred_class")
  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, data)$.pred_class)
  )
})

test_that("bag_tree(rpart) works with type = class for multiclass outcomes", {
  skip_if_no_baguette()
  skip_if_not_installed("rpart")

  spec <- parsnip::set_engine(
    parsnip::set_mode(parsnip::bag_tree(), "classification"),
    "rpart"
  )
  fit <- parsnip::fit(spec, Species ~ ., iris)

  preds <- predict(orbital(fit, type = "class"), iris)

  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, iris)$.pred_class)
  )
})

test_that("bag_tree(C5.0) works with type = class", {
  skip_if_no_baguette()
  skip_if_not_installed("C50")

  spec <- parsnip::set_engine(
    parsnip::set_mode(parsnip::bag_tree(), "classification"),
    "C5.0"
  )
  fit <- parsnip::fit(spec, Species ~ ., iris)

  preds <- predict(orbital(fit, type = "class"), iris)

  expect_identical(
    preds$.pred_class,
    as.character(predict(fit, iris)$.pred_class)
  )
})

test_that("bag_tree() errors for type = prob", {
  skip_if_no_baguette()
  skip_if_not_installed("rpart")

  spec <- parsnip::set_engine(
    parsnip::set_mode(parsnip::bag_tree(), "classification"),
    "rpart"
  )
  fit <- parsnip::fit(spec, Species ~ ., iris)

  expect_snapshot(error = TRUE, orbital(fit, type = "prob"))
})
