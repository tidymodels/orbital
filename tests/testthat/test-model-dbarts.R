skip_if_no_dbarts <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("dbarts")
}

# `predict()` on a BART model draws from the posterior, so it returns different
# numbers on every call and cannot be used as a reference. Compare against the
# formula tidypredict extracts from the fit instead.
tidypredict_reference <- function(fit, data) {
  rlang::eval_tidy(
    tidypredict::tidypredict_fit(fit$fit),
    data = data,
    env = asNamespace("dplyr")
  )
}

test_that("bart(dbarts) works with type = numeric", {
  skip_if_no_dbarts()

  spec <- parsnip::bart(trees = 5, mode = "regression", engine = "dbarts")

  set.seed(1234)
  fit <- parsnip::fit(spec, mpg ~ disp + vs + hp, mtcars)

  preds <- predict(orbital(fit), mtcars)

  expect_named(preds, ".pred")
  expect_type(preds$.pred, "double")
  expect_equal(preds$.pred, tidypredict_reference(fit, mtcars))
})

test_that("bart(dbarts) works with custom prefix", {
  skip_if_no_dbarts()

  spec <- parsnip::bart(trees = 5, mode = "regression", engine = "dbarts")

  set.seed(1234)
  fit <- parsnip::fit(spec, mpg ~ disp + vs + hp, mtcars)

  preds <- predict(orbital(fit, prefix = "my_pred"), mtcars)

  expect_named(preds, "my_pred")
})

test_that("bart(dbarts) errors for classification", {
  skip_if_no_dbarts()

  mtcars$vs <- factor(mtcars$vs)

  spec <- parsnip::bart(trees = 5, mode = "classification", engine = "dbarts")

  set.seed(1234)
  fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)

  expect_snapshot(error = TRUE, orbital(fit, type = "class"))
})
