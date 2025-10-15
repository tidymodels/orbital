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

test_that("spark - adjust_equivocal_zone works", {
  skip_if_not_installed("tailor")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")
  skip_if_not_installed("probably")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_eq <- mtcars
  mtcars_eq$vs <- factor(mtcars_eq$vs)

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

  wf_fit <- workflows::fit(workflow, mtcars_eq)

  orb_fit <- orbital(wf_fit, type = c("prob", "class"))

  exp <- as.character(predict(wf_fit, mtcars_eq)$.pred_class)
  exp[is.na(exp)] <- "[EQ]"

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_eq")

  expect_identical(
    dplyr::pull(predict(orb_fit, mtcars_tbl), .pred_class),
    exp
  )
})

test_that("SQLite - adjust_equivocal_zone works", {
  skip_if_not_installed("tailor")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")
  skip_if_not_installed("probably")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  skip_on_cran()

  mtcars_eq <- mtcars
  mtcars_eq$vs <- factor(mtcars_eq$vs)

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

  wf_fit <- workflows::fit(workflow, mtcars_eq)

  orb_fit <- orbital(wf_fit, type = c("prob", "class"))

  exp <- as.character(predict(wf_fit, mtcars_eq)$.pred_class)
  exp[is.na(exp)] <- "[EQ]"

  con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
  mtcars_tbl <- dplyr::copy_to(con, mtcars_eq)

  expect_identical(
    dplyr::pull(predict(orb_fit, mtcars_tbl), .pred_class),
    exp
  )
  DBI::dbDisconnect(con)
})

test_that("duckdb - adjust_equivocal_zone works", {
  skip_if_not_installed("tailor")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")
  skip_if_not_installed("probably")
  skip_if_not_installed("DBI")
  skip_if_not_installed("duckdb")

  mtcars_eq <- mtcars
  mtcars_eq$vs <- factor(mtcars_eq$vs)

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

  wf_fit <- workflows::fit(workflow, mtcars_eq)

  orb_fit <- orbital(wf_fit, type = c("prob", "class"))

  exp <- as.character(predict(wf_fit, mtcars_eq)$.pred_class)
  exp[is.na(exp)] <- "[EQ]"

  con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
  mtcars_tbl <- dplyr::copy_to(con, mtcars_eq)

  expect_identical(
    dplyr::pull(predict(orb_fit, mtcars_tbl), .pred_class),
    exp
  )
  DBI::dbDisconnect(con)
})

test_that("arrow - adjust_equivocal_zone works", {
  skip_if_not_installed("tailor")
  skip_if_not_installed("parsnip")
  skip_if_not_installed("workflows")
  skip_if_not_installed("probably")
  skip_if_not_installed("arrow")

  mtcars_eq <- mtcars
  mtcars_eq$vs <- factor(mtcars_eq$vs)

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

  wf_fit <- workflows::fit(workflow, mtcars_eq)

  orb_fit <- orbital(wf_fit, type = c("prob", "class"))

  exp <- as.character(predict(wf_fit, mtcars_eq)$.pred_class)
  exp[is.na(exp)] <- "[EQ]"

  mtcars_tbl <- arrow::as_arrow_table(mtcars_eq)

  expect_identical(
    dplyr::collect(predict(orb_fit, mtcars_tbl))$.pred_class,
    exp
  )
})
