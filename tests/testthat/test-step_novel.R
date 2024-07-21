test_that("step_novel works", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[2:4, ] <- NA
  mtcars$gear <- letters[mtcars$gear]
  mtcars$carb <- letters[mtcars$carb]

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_novel(recipes::all_nominal_predictors()) %>%
    recipes::prep(strings_as_factors = FALSE)

  mtcars[1, 10] <- "aaaaa"

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]
  exp$gear <- as.character(exp$gear)
  exp$carb <- as.character(exp$carb)

  expect_equal(res, exp)
})

test_that("step_novel works with empty selections", {
  skip_if_not_installed("recipes")

  mtcars <- dplyr::as_tibble(mtcars)
  mtcars[2:4, ] <- NA
  mtcars$gear <- letters[mtcars$gear]
  mtcars$carb <- letters[mtcars$carb]

  rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
    recipes::step_novel() %>%
    recipes::prep(strings_as_factors = FALSE)

  mtcars[1, 10] <- "aaaaa"

  res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

  exp <- recipes::bake(rec, new_data = mtcars)
  exp <- exp[names(res)]
  exp$gear <- as.character(exp$gear)
  exp$carb <- as.character(exp$carb)

  expect_equal(res, exp)
})

test_that("spark - step_novel works", {
  skip_if_not_installed("recipes")
  skip_if_not_installed("sparklyr")
  skip_if(is.na(testthat_spark_env_version()))

  mtcars_novel <- dplyr::as_tibble(mtcars)
  mtcars_novel$gear <- letters[mtcars$gear]
  mtcars_novel$carb <- letters[mtcars$carb]
  mtcars_novel[2:4, ] <- NA

  rec <- recipes::recipe(mpg ~ ., data = mtcars_novel) %>%
    recipes::step_novel(recipes::all_nominal_predictors()) %>%
    recipes::prep()

  mtcars_novel[1, 10] <- "aaaaa"

  res <- dplyr::mutate(mtcars_novel, !!!orbital_inline(orbital(rec)))

  sc <- testthat_spark_connection()
  mtcars_tbl <- testthat_tbl("mtcars_novel")

  res_spark <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
    dplyr::collect()

  expect_equal(res_spark, res)
})



