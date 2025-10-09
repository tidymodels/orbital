test_that("orbital works with tailor alone", {
  skip_if_not_installed("tailor")

  tlr <- tailor::tailor() |>
    tailor::adjust_predictions_custom(
      half = mpg / 2
    )

  tlr_fit <- tailor::fit(
    tlr,
    mtcars,
    outcome = c(mpg),
    estimate = c(disp)
  )

  res <- orbital(tlr_fit)

  expect_s3_class(res, "orbital_class")
  expect_identical(
    unclass(res),
    c(half = "mpg/2")
  )

  expect_identical(
    predict(tlr_fit, mtcars),
    predict(res, tibble::as_tibble(mtcars))
  )
})

test_that("orbital works with tailor and workflows", {
  skip_if_not_installed("tailor")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")

  mod <- parsnip::linear_reg()
  mod <- parsnip::set_engine(mod, "lm")

  workflow <- workflows::workflow()
  workflow <- workflows::add_formula(workflow, mpg ~ cyl)
  workflow <- workflows::add_model(workflow, mod)

  tailor <- tailor::tailor()
  tailor <- tailor::adjust_predictions_custom(tailor, .pred = .pred / 5)
  workflow <- workflows::add_tailor(workflow, tailor)

  wf_fit <- workflows::fit(workflow, mtcars)

  orb <- orbital(wf_fit)

  expect_equal(
    predict(orb, tibble::as_tibble(mtcars)),
    predict(wf_fit, mtcars)
  )
})

test_that("works with empty tailor in workflow", {
  skip_if_not_installed("tailor")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")

  mod <- parsnip::linear_reg()
  mod <- parsnip::set_engine(mod, "lm")

  workflow <- workflows::workflow()
  workflow <- workflows::add_formula(workflow, mpg ~ cyl)
  workflow <- workflows::add_model(workflow, mod)

  tailor <- tailor::tailor()
  workflow <- workflows::add_tailor(workflow, tailor)

  wf_fit <- workflows::fit(workflow, mtcars)

  orb <- orbital(wf_fit)

  expect_equal(
    predict(orb, tibble::as_tibble(mtcars)),
    predict(wf_fit, mtcars)
  )
})
