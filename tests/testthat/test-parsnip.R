test_that("normal usage works works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("kknn")

  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::nearest_neighbor(mode = "regression")

  wf_spec <- workflows::workflow(rec_spec, lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  expect_snapshot(
    error = TRUE,
    orbital(wf_fit)
  )
})

test_that("has_orbital_method() detects native methods", {
  expect_all_true(c(
    has_orbital_method(structure(list(), class = "glm")),
    has_orbital_method(structure(list(), class = "ranger")),
    has_orbital_method(structure(list(), class = "xgb.Booster"))
  ))

  # `orbital.default` exists, so a missing method must not be inferred from a
  # failed call: it errors like any other bug would.
  expect_false(has_orbital_method(structure(list(), class = "train.kknn")))
})

test_that("errors from native methods are not swallowed by the fallback", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")

  local_mocked_bindings(
    orbital.glm = function(...) cli::cli_abort("Bug inside a native method.")
  )

  mtcars$vs <- factor(mtcars$vs)
  fit <- parsnip::fit(
    parsnip::logistic_reg(),
    vs ~ disp + hp,
    mtcars
  )

  # Previously this was caught by `try()` and quietly replaced with a
  # tidypredict result, so a broken native method still returned an answer.
  expect_snapshot(error = TRUE, orbital(fit))
})

test_that("prefix argument works", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("tidypredict")

  lm_spec <- parsnip::linear_reg()

  lm_fit <- parsnip::fit(lm_spec, mpg ~ ., mtcars)

  orb_obj <- orbital(lm_fit, prefix = "pred")

  expect_true("pred" %in% names(orb_obj))
  expect_false(".pred" %in% names(orb_obj))

  lr_spec <- parsnip::logistic_reg()

  mtcars$vs <- factor(mtcars$vs)

  lr_fit <- parsnip::fit(lr_spec, vs ~ disp, mtcars)

  orb_obj <- orbital(lr_fit, prefix = "pred")

  expect_true("pred_class" %in% names(orb_obj))
  expect_false(".pred_class" %in% names(orb_obj))
})

test_that("errors on invalid modes", {
  skip_if_not_installed("parsnip")

  lm_spec <- parsnip::linear_reg()

  lm_fit <- parsnip::fit(lm_spec, mpg ~ ., mtcars)

  lm_fit$spec$mode <- "invalid mode"

  expect_snapshot(
    error = TRUE,
    orbital(lm_fit)
  )
})

test_that("type argument checking works", {
  skip_if_not_installed("tidypredict")
  lm_spec <- parsnip::linear_reg()

  lm_fit <- parsnip::fit(lm_spec, mpg ~ ., mtcars)

  expect_no_error(
    orbital(lm_fit, type = "numeric")
  )

  expect_snapshot(
    error = TRUE,
    orbital(lm_fit, type = "invalid")
  )
  expect_snapshot(
    error = TRUE,
    orbital(lm_fit, type = "class")
  )
  expect_snapshot(
    error = TRUE,
    orbital(lm_fit, type = c("class", "numeric"))
  )

  lm_spec <- parsnip::logistic_reg()

  mtcars$vs <- factor(mtcars$vs)

  lm_fit <- parsnip::fit(lm_spec, vs ~ disp, mtcars)

  expect_no_error(
    orbital(lm_fit, type = "class")
  )

  expect_no_error(
    orbital(lm_fit, type = c("class", "prob"))
  )

  expect_snapshot(
    error = TRUE,
    orbital(lm_fit, type = "invalid")
  )
  expect_snapshot(
    error = TRUE,
    orbital(lm_fit, type = "numeric")
  )
  expect_snapshot(
    error = TRUE,
    orbital(lm_fit, type = c("class", "numeric"))
  )
})
