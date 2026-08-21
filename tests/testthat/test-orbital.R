test_that("orbital works with workflows - recipe", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("workflows")
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() |>
    workflows::add_recipe(rec_spec) |>
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  res <- orbital(wf_fit)

  expect_s3_class(res, "orbital_class")
  expect_true(is.character(res))
  expect_named(res)
  expect_length(res, 1 + (ncol(mtcars) - 1))
})

test_that("orbital works with workflows - formula", {
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("workflows")
  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() |>
    workflows::add_formula(mpg ~ .) |>
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  res <- orbital(wf_fit)

  expect_s3_class(res, "orbital_class")
  expect_true(is.character(res))
  expect_named(res, ".pred")
  expect_length(res, 1)
})

test_that("orbital works with workflows - variables", {
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("workflows")
  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow() |>
    workflows::add_variables(outcomes = "mpg", predictors = everything()) |>
    workflows::add_model(lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  res <- orbital(wf_fit)

  expect_s3_class(res, "orbital_class")
  expect_true(is.character(res))
  expect_named(res, ".pred")
  expect_length(res, 1)
})

test_that("orbital errors on non-trained workflow", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("workflows")
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow(rec_spec, lm_spec)

  expect_snapshot(
    error = TRUE,
    orbital(wf_spec)
  )
})

test_that("orbital works with recipe", {
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("recipes")
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_normalize(recipes::all_numeric_predictors())

  rec_prep <- recipes::prep(rec_spec)

  res <- orbital(rec_prep)

  expect_s3_class(res, "orbital_class")
  expect_true(is.character(res))
  expect_named(res)
})

test_that("orbital errors untrained recipe", {
  skip_if_not_installed("recipes")
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_normalize(recipes::all_numeric_predictors())

  expect_snapshot(
    error = TRUE,
    orbital(rec_spec)
  )
})

test_that("orbital works with parsnip", {
  skip_if_not_installed("tidypredict")
  lm_spec <- parsnip::linear_reg()

  lm_fit <- parsnip::fit(lm_spec, mpg ~ ., data = mtcars)

  res <- orbital(lm_fit)

  expect_s3_class(res, "orbital_class")
  expect_true(is.character(res))
  expect_named(res, ".pred")
})

test_that("orbital errors on non-trained parsnip", {
  skip_if_not_installed("parsnip")
  lm_spec <- parsnip::linear_reg()

  expect_snapshot(
    error = TRUE,
    orbital(lm_spec)
  )
})

test_that("orbital errors on wrong input", {
  expect_snapshot(
    error = TRUE,
    orbital(lm(mpg ~ ., data = mtcars))
  )
})

test_that("orbital printing works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("workflows")
  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow(rec_spec, lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  # Use transform to normalize floating-point differences across platforms
  # by rounding numbers to 4 decimal places
  round_numbers <- function(x) {
    gsub(
      "(-?[0-9]+\\.[0-9]{4})[0-9]+",
      "\\1",
      x
    )
  }

  expect_snapshot(
    orbital(wf_fit),
    transform = round_numbers
  )

  expect_snapshot(
    print(orbital(wf_fit), digits = 2)
  )

  expect_snapshot(
    print(orbital(wf_fit), truncate = FALSE),
    transform = round_numbers
  )
})

test_that("pretty_print rounds each number in place", {
  expect_identical(
    pretty_print("(6.75044994983228 + (disp * -0.00377603284098302))"),
    "(6.75045 + (disp * -0.003776033))"
  )

  # A regex-matched number must not be re-substituted by a later match: "0.5"
  # as a regex once turned "6.75045" into "6.750.5", and "0.0" applied twice
  # turned "0.09017198" into "017198".
  expect_identical(
    pretty_print("0.0901719835820594 END * 0.5 + 0.0"),
    "0.09017198 END * 0.5 + 0"
  )

  # Each element is rounded using its own matches, not the whole vector's.
  expect_identical(
    pretty_print(c("a 1.55555555 b", "c 2.66666666 d"), digits = 3),
    c("a 1.56 b", "c 2.67 d")
  )
})

test_that("prefix argument works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")
  skip_if_not_installed("tidypredict")

  rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) |>
    recipes::step_normalize(recipes::all_numeric_predictors())

  lm_spec <- parsnip::linear_reg()

  wf_spec <- workflows::workflow(rec_spec, lm_spec)

  wf_fit <- parsnip::fit(wf_spec, mtcars)

  orb_obj <- orbital(wf_fit, prefix = "pred")

  expect_true("pred" %in% names(orb_obj))
  expect_false(".pred" %in% names(orb_obj))
})
