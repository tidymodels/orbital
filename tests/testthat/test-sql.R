test_that("sql works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("workflows")

  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() |>
    workflows::add_recipe(rec_spec) |>
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  obj <- orbital(wf_fit)

  con <- dbplyr::simulate_dbi()

  expect_snapshot(
    transform = orbital:::pretty_print,
    orbital_sql(obj, con)
  )
})

test_that("sql works for glmnet classification", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("glmnet")

  mtcars$vs <- factor(mtcars$vs)
  spec <- parsnip::logistic_reg(penalty = 0.01, engine = "glmnet")
  fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)

  obj <- orbital(fit, type = c("class", "prob"))

  con <- dbplyr::simulate_dbi()

  expect_snapshot(
    transform = orbital:::pretty_print,
    orbital_sql(obj, con)
  )
})

test_that("sql works for glmnet multiclass", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("glmnet")

  spec <- parsnip::multinom_reg(penalty = 0.01, engine = "glmnet")
  fit <- parsnip::fit(spec, Species ~ ., iris)

  obj <- orbital(fit, type = c("class", "prob"))

  con <- dbplyr::simulate_dbi()

  expect_snapshot(
    transform = orbital:::pretty_print,
    orbital_sql(obj, con)
  )
})

test_that("sql works for earth classification", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("earth")

  mtcars$vs <- factor(mtcars$vs)
  spec <- parsnip::mars(mode = "classification", engine = "earth")

  suppressWarnings(
    fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)
  )

  obj <- orbital(fit, type = c("class", "prob"))

  con <- dbplyr::simulate_dbi()

  expect_snapshot(
    transform = orbital:::pretty_print,
    orbital_sql(obj, con)
  )
})

test_that("sql works for randomForest classification", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("randomForest")

  mtcars$vs <- factor(mtcars$vs)
  spec <- parsnip::rand_forest(
    trees = 3,
    mode = "classification",
    engine = "randomForest"
  )

  set.seed(123)
  fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)

  obj <- orbital(fit, type = c("class", "prob"))

  con <- dbplyr::simulate_dbi()

  expect_snapshot(
    transform = orbital:::pretty_print,
    orbital_sql(obj, con)
  )
})

test_that("sql works for ranger classification", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("ranger")

  mtcars$vs <- factor(mtcars$vs)
  spec <- parsnip::rand_forest(
    trees = 3,
    mode = "classification",
    engine = "ranger"
  ) |>
    parsnip::set_engine("ranger", seed = 1234)

  fit <- parsnip::fit(spec, vs ~ disp + mpg + hp, mtcars)

  obj <- orbital(fit, type = c("class", "prob"))

  con <- dbplyr::simulate_dbi()

  # Don't use snapshot - ranger results vary across platforms even with seed
  res <- orbital_sql(obj, con)
  expect_s3_class(res, "sql")
  expect_length(res, 5)
})

test_that("sql works for lda multiclass", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("discrim")
  skip_if_not_installed("MASS")

  spec <- parsnip::set_engine(parsnip::discrim_linear(), "MASS")
  fit <- parsnip::fit(spec, Species ~ ., iris)

  obj <- orbital(fit, type = c("class", "prob"))

  con <- dbplyr::simulate_dbi()

  expect_snapshot(
    transform = orbital:::pretty_print,
    orbital_sql(obj, con)
  )
})

test_that("sql works for a binary decision value", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("LiblineaR")

  # LiblineaR's solver is seeded from R's RNG, so its coefficients move between
  # runs and the snapshot would not be stable without this.
  set.seed(123)
  spec <- parsnip::svm_linear(mode = "classification", engine = "LiblineaR")
  fit <- parsnip::fit(spec, Species ~ ., two_species_iris())

  obj <- orbital(fit, type = "class")

  con <- dbplyr::simulate_dbi()

  expect_snapshot(
    transform = orbital:::pretty_print,
    orbital_sql(obj, con)
  )
})

test_that("sql works for a binary probability cut away from 0.5", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("kernlab")

  # kernlab carries its own cut, so the threshold in the query is a full
  # precision literal rather than the 0.5 every other binary model uses.
  set.seed(123)
  spec <- parsnip::svm_linear(mode = "classification", engine = "kernlab")
  fit <- parsnip::fit(spec, Species ~ ., two_species_iris())

  obj <- orbital(fit, type = c("class", "prob"))

  con <- dbplyr::simulate_dbi()

  expect_snapshot(
    transform = orbital:::pretty_print,
    orbital_sql(obj, con)
  )
})
