# aorsf splits on observed linear-combination values, so a training row can land
# exactly on a split boundary where floating-point drift flips the branch. These
# tests predict on jittered data, where such exact ties do not occur.
skip_if_no_aorsf <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("aorsf")
}

jittered_mtcars <- function() {
  set.seed(99)
  df <- mtcars
  df[] <- lapply(mtcars, function(x) x + stats::rnorm(length(x), 0, 0.01))
  df
}

test_that("rand_forest(aorsf) works for regression", {
  skip_if_no_aorsf()

  set.seed(1)
  spec <- parsnip::set_engine(
    parsnip::rand_forest(mode = "regression", trees = 20),
    "aorsf"
  )
  fit <- parsnip::fit(spec, mpg ~ wt + cyl + disp + hp, mtcars)

  new_data <- jittered_mtcars()
  preds <- predict(orbital(fit), new_data)

  expect_named(preds, ".pred")
  expect_equal(preds$.pred, predict(fit, new_data)$.pred)
})

test_that("rand_forest(aorsf) works with custom prefix", {
  skip_if_no_aorsf()

  set.seed(1)
  spec <- parsnip::set_engine(
    parsnip::rand_forest(mode = "regression", trees = 5),
    "aorsf"
  )
  fit <- parsnip::fit(spec, mpg ~ wt + cyl, mtcars)

  preds <- predict(orbital(fit, prefix = "my_pred"), jittered_mtcars())

  expect_named(preds, "my_pred")
})

test_that("rand_forest(aorsf) errors for classification", {
  skip_if_no_aorsf()

  set.seed(1)
  spec <- parsnip::set_engine(
    parsnip::rand_forest(mode = "classification", trees = 5),
    "aorsf"
  )
  fit <- parsnip::fit(
    spec,
    Species ~ .,
    droplevels(iris[iris$Species != "setosa", ])
  )

  expect_snapshot(error = TRUE, orbital(fit))
})
