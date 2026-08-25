binary_iris <- function() {
  df <- iris
  df$Species <- factor(df$Species == "setosa", labels = c("no", "yes"))
  df
}

test_that("multiclass probabilities route through the adapter", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("discrim")
  skip_if_not_installed("MASS")

  fit <- parsnip::fit(
    parsnip::set_engine(parsnip::discrim_linear(), "MASS"),
    Species ~ .,
    data = iris
  )

  obj <- orbital(fit, type = c("class", "prob"))
  preds <- predict(obj, iris)

  expect_equal(
    as.matrix(preds[, c(
      ".pred_setosa",
      ".pred_versicolor",
      ".pred_virginica"
    )]),
    as.matrix(predict(fit, iris, type = "prob")),
    ignore_attr = TRUE
  )
  expect_equal(preds$.pred_class, as.character(predict(fit, iris)$.pred_class))
})

test_that("probabilities are reordered into parsnip's level order", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("discrim")
  skip_if_not_installed("MASS")

  # Reversing the factor levels makes model order and parsnip order disagree,
  # so a positional pass-through would mislabel every column.
  df <- iris
  df$Species <- factor(df$Species, levels = rev(levels(df$Species)))

  fit <- parsnip::fit(
    parsnip::set_engine(parsnip::discrim_linear(), "MASS"),
    Species ~ .,
    data = df
  )

  obj <- orbital(fit, type = "prob")
  preds <- predict(obj, df)

  expect_equal(
    as.matrix(preds),
    as.matrix(predict(fit, df, type = "prob")),
    ignore_attr = TRUE
  )
})

test_that("a decision value routes to a cut at zero, and refuses prob", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("LiblineaR")

  df <- binary_iris()
  fit <- parsnip::fit(
    parsnip::set_mode(
      parsnip::set_engine(parsnip::svm_linear(), "LiblineaR"),
      "classification"
    ),
    Species ~ .,
    data = df
  )

  obj <- orbital(fit, type = "class")

  expect_equal(
    predict(obj, df)$.pred_class,
    as.character(predict(fit, df)$.pred_class)
  )
  expect_snapshot(error = TRUE, orbital(fit, type = "prob"))
})

test_that("a class-only model routes its label through, and refuses prob", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("C50")

  fit <- parsnip::fit(
    parsnip::set_mode(
      parsnip::set_engine(parsnip::boost_tree(trees = 3), "C5.0"),
      "classification"
    ),
    Species ~ .,
    data = iris
  )

  obj <- orbital(fit, type = "class")

  expect_equal(
    predict(obj, iris)$.pred_class,
    as.character(predict(fit, iris)$.pred_class)
  )
  expect_snapshot(error = TRUE, orbital(fit, type = "prob"))
})

test_that("a model tidypredict cannot describe is refused", {
  local_mocked_bindings(
    tidypredict_output_type = function(x, ...) {
      cli::cli_abort("no", class = "tidypredict_no_metadata")
    }
  )

  fit <- structure(
    list(fit = structure(list(), class = "made_up"), lvl = c("a", "b")),
    class = c("_made_up", "model_fit")
  )

  expect_snapshot(
    error = TRUE,
    route_fallback(rlang::expr(1 + 1), fit, "classification", "class")
  )
})

test_that("regression output passes through untouched", {
  fit <- structure(list(), class = c("_made_up", "model_fit"))
  eq <- rlang::expr(1 + 1)

  expect_identical(route_fallback(eq, fit, "regression", "numeric"), eq)
})

test_that("a level-count mismatch is refused", {
  fit <- structure(
    list(fit = structure(list(), class = "made_up"), lvl = c("a", "b", "c")),
    class = c("_made_up", "model_fit")
  )

  expect_snapshot(
    error = TRUE,
    order_prob_eqs(c(a = "1", b = "2"), fit, fit$lvl, rlang::current_env())
  )
})
