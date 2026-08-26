skip_if_no_sparsediscrim <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("discrim")
  skip_if_not_installed("sparsediscrim")
}

sparsediscrim_fit <- function(method, data = iris) {
  parsnip::fit(
    parsnip::discrim_linear(
      engine = "sparsediscrim",
      regularization_method = method
    ),
    Species ~ .,
    data
  )
}

methods <- c("diagonal", "shrink_mean", "shrink_cov")

for (method in methods) {
  test_that(paste0("discrim_linear(sparsediscrim, ", method, ") works"), {
    skip_if_no_sparsediscrim()

    fit <- sparsediscrim_fit(method)
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
}

test_that("discrim_linear(sparsediscrim) probabilities follow level order", {
  skip_if_no_sparsediscrim()

  data <- iris
  data$Species <- factor(data$Species, levels = rev(levels(data$Species)))

  fit <- sparsediscrim_fit("diagonal", data)
  preds <- predict(orbital(fit, type = "prob"), data)

  expect_named(preds, c(".pred_virginica", ".pred_versicolor", ".pred_setosa"))
  expect_equal(
    as.matrix(preds),
    as.matrix(predict(fit, data, type = "prob")),
    ignore_attr = TRUE
  )
})

test_that("discrim_linear(sparsediscrim) works with a custom prefix", {
  skip_if_no_sparsediscrim()

  fit <- sparsediscrim_fit("diagonal")
  preds <- predict(orbital(fit, type = c("class", "prob"), prefix = "p"), iris)

  expect_named(preds, c("p_class", "p_setosa", "p_versicolor", "p_virginica"))
})
