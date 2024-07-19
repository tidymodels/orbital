test_that("step_discretize works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[1, ] <- NA

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      recipes::step_discretize(mpg, disp, min_unique = 4) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]
  exp$mpg <- as.character(exp$mpg)
  exp$disp <- as.character(exp$disp)

  expect_equal(res, exp)
})

test_that("step_discretize works num_breaks = 2", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[1, ] <- NA

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      recipes::step_discretize(vs, am, min_unique = 1, num_breaks = 2) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]
  exp$am <- as.character(exp$am)
  exp$vs <- as.character(exp$vs)

  expect_equal(res, exp)
})

test_that("step_discretize works when min_unique is too high", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[1, ] <- NA

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
      recipes::step_discretize(mpg, disp, min_unique = 100) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]

  expect_equal(res, exp)
})

test_that("spark - step_discretize works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_discretize <- dplyr::as_tibble(mtcars)
  mtcars_discretize[1, ] <- NA

  suppressWarnings(
    rec <- recipes::recipe(mpg ~ ., data = mtcars_discretize) %>%
      recipes::step_discretize(mpg, disp, min_unique = 4) %>%
      recipes::prep()
  )

  res <- dplyr::mutate(mtcars_discretize, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_discretize")

  res_spark <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_spark, res)
})



