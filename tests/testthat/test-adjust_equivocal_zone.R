test_that("adjust_equivocal_zone works", {
  skip_if_not_installed("tailor")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")
  skip_if_not_installed("probably")

  mtcars$vs <- factor(mtcars$vs)

  mod <- parsnip::logistic_reg()

  workflow <- workflows::workflow()
  workflow <- workflows::add_formula(workflow, vs ~ disp)
  workflow <- workflows::add_model(workflow, mod)

  tailor <- tailor::tailor()
  tailor <- tailor::adjust_equivocal_zone(
    tailor,
    value = 1 / 4,
    threshold = 0.3
  )
  workflow <- workflows::add_tailor(workflow, tailor)

  wf_fit <- workflows::fit(workflow, mtcars)

  orb_fit <- orbital(wf_fit, type = c("prob", "class"))

  exp <- as.character(predict(wf_fit, mtcars)$.pred_class)
  exp[is.na(exp)] <- "[EQ]"

  expect_identical(
    predict(orb_fit, mtcars)$.pred_class,
    exp
  )
})

test_that("adjust_equivocal_zone errors if types aren't set", {
  skip_if_not_installed("tailor")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")
  skip_if_not_installed("probably")

  mtcars$vs <- factor(mtcars$vs)

  mod <- parsnip::logistic_reg()

  workflow <- workflows::workflow()
  workflow <- workflows::add_formula(workflow, vs ~ disp)
  workflow <- workflows::add_model(workflow, mod)

  tailor <- tailor::tailor()
  tailor <- tailor::adjust_equivocal_zone(tailor, value = 1 / 4)
  workflow <- workflows::add_tailor(workflow, tailor)

  wf_fit <- workflows::fit(workflow, mtcars)

  expect_snapshot(
    error = TRUE,
    orbital(wf_fit)
  )

  expect_snapshot(
    error = TRUE,
    orbital(wf_fit, type = "prob")
  )

  expect_snapshot(
    error = TRUE,
    orbital(wf_fit, type = "class")
  )
})

test_that("adjust_equivocal_zone works with prefix argument", {
  skip_if_not_installed("tailor")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")
  skip_if_not_installed("probably")

  mtcars$vs <- factor(mtcars$vs)

  mod <- parsnip::logistic_reg()

  workflow <- workflows::workflow()
  workflow <- workflows::add_formula(workflow, vs ~ disp)
  workflow <- workflows::add_model(workflow, mod)

  tailor <- tailor::tailor()
  tailor <- tailor::adjust_equivocal_zone(
    tailor,
    value = 1 / 4,
    threshold = 0.3
  )
  workflow <- workflows::add_tailor(workflow, tailor)

  wf_fit <- workflows::fit(workflow, mtcars)

  orb_fit <- orbital(wf_fit, type = c("prob", "class"), prefix = "potato")

  exp <- as.character(predict(wf_fit, mtcars)$.pred_class)
  exp[is.na(exp)] <- "[EQ]"

  expect_identical(
    predict(orb_fit, mtcars)$potato_class,
    exp
  )
})
