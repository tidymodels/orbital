test_that("dt works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("dtplyr")
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

  expect_snapshot(
    transform = orbital:::pretty_print,
    orbital_dt(obj)
  )
})

test_that("dt works for lda multiclass", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("dtplyr")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("discrim")
  skip_if_not_installed("MASS")

  spec <- parsnip::set_engine(parsnip::discrim_linear(), "MASS")
  fit <- parsnip::fit(spec, Species ~ ., iris)

  obj <- orbital(fit, type = c("class", "prob"))

  expect_snapshot(
    transform = orbital:::pretty_print,
    orbital_dt(obj)
  )
})
