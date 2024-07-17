test_that("step_other works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[2:4, ] <- NA
  mtcars$gear <- letters[mtcars$gear]
  mtcars$carb <- letters[mtcars$carb]
  mtcars$gear[1] <- "aa"
  mtcars$carb[1] <- "aa"

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_other(recipes::all_nominal_predictors()) %>%
    recipes::prep(strings_as_factors = FALSE)

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]
  exp$gear <- as.character(exp$gear)
  exp$carb <- as.character(exp$carb)

  expect_equal(res, exp)
})

test_that("spark - step_other works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_other <- dplyr::as_tibble(mtcars)
  mtcars_other$gear <- letters[mtcars$gear]
  mtcars_other$carb <- letters[mtcars$carb]
  mtcars_other[2:4, ] <- NA
  mtcars_other$gear[1] <- "aa"
  mtcars_other$carb[1] <- "aa"

  rec <- recipes::recipe(mpg ~ ., data = mtcars_other) %>%
    recipes::step_other(recipes::all_nominal_predictors()) %>%
    recipes::prep()

  res <- dplyr::mutate(mtcars_other, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_other")

  res_spark <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_spark, res)
})



