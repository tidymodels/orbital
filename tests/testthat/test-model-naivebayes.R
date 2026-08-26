skip_if_no_naive_bayes <- function(engine) {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("discrim")
  skip_if_not_installed(engine)
}

# Both engines default to `usekernel = TRUE`, which fits a kernel density per
# predictor and has no closed form to translate. Only the Gaussian fit does.
naive_bayes_fit <- function(engine, data = iris) {
  parsnip::fit(
    parsnip::set_engine(parsnip::naive_Bayes(), engine, usekernel = FALSE),
    Species ~ .,
    data
  )
}

for (engine in c("klaR", "naivebayes")) {
  test_that(paste0("naive_Bayes(", engine, ") works"), {
    skip_if_no_naive_bayes(engine)

    fit <- naive_bayes_fit(engine)
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

  test_that(paste0("naive_Bayes(", engine, ") refuses kernel density fits"), {
    skip_if_no_naive_bayes(engine)

    fit <- parsnip::fit(
      parsnip::set_engine(parsnip::naive_Bayes(), engine, usekernel = TRUE),
      Species ~ .,
      iris
    )

    expect_snapshot(error = TRUE, orbital(fit, type = "prob"))
  })
}

test_that("naive_Bayes() probabilities follow the outcome's level order", {
  skip_if_no_naive_bayes("naivebayes")

  data <- iris
  data$Species <- factor(data$Species, levels = rev(levels(data$Species)))

  fit <- naive_bayes_fit("naivebayes", data)
  preds <- predict(orbital(fit, type = "prob"), data)

  expect_named(preds, c(".pred_virginica", ".pred_versicolor", ".pred_setosa"))
  expect_equal(
    as.matrix(preds),
    as.matrix(predict(fit, data, type = "prob")),
    ignore_attr = TRUE
  )
})

test_that("naive_Bayes() works with a custom prefix", {
  skip_if_no_naive_bayes("naivebayes")

  fit <- naive_bayes_fit("naivebayes")
  preds <- predict(orbital(fit, type = c("class", "prob"), prefix = "p"), iris)

  expect_named(preds, c("p_class", "p_setosa", "p_versicolor", "p_virginica"))
})
