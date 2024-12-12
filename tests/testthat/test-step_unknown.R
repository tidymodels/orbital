test_that("step_unknown works", {
	skip_if_not_installed("recipes")

	mtcars <- dplyr::as_tibble(mtcars)
	mtcars$gear <- letters[mtcars$gear]
	mtcars$carb <- letters[mtcars$carb]
	mtcars[2:4, ] <- NA

	rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
		recipes::step_unknown(recipes::all_nominal_predictors()) %>%
		recipes::prep()

	res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

	exp <- recipes::bake(rec, new_data = mtcars)
	exp <- exp[names(res)]
	exp$gear <- as.character(exp$gear)
	exp$carb <- as.character(exp$carb)

	expect_equal(res, exp)
})

test_that("step_unknown only calculates what is sufficient", {
	skip_if_not_installed("recipes")

	mtcars <- dplyr::as_tibble(mtcars)
	mtcars$gear <- letters[mtcars$gear]
	mtcars$carb <- letters[mtcars$carb]
	mtcars[2:4, ] <- NA

	rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
		recipes::step_unknown(recipes::all_nominal_predictors()) %>%
		recipes::step_rm(gear) %>%
		recipes::prep()

	expect_identical(
		names(orbital(rec)),
		"carb"
	)
})

test_that("step_unknown works with empty selections", {
	skip_if_not_installed("recipes")

	mtcars <- dplyr::as_tibble(mtcars)
	mtcars$gear <- letters[mtcars$gear]
	mtcars$carb <- letters[mtcars$carb]
	mtcars[2:4, ] <- NA

	rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
		recipes::step_unknown() %>%
		recipes::prep()

	res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

	exp <- recipes::bake(rec, new_data = mtcars)
	exp <- exp[names(res)]
	exp$gear <- as.character(exp$gear)
	exp$carb <- as.character(exp$carb)

	expect_equal(res, exp)
})

test_that("spark - step_unknown works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("sparklyr")
	skip_if(is.na(testthat_spark_env_version()))

	mtcars_unknown <- dplyr::as_tibble(mtcars)
	mtcars_unknown$gear <- letters[mtcars$gear]
	mtcars_unknown$carb <- letters[mtcars$carb]
	mtcars_unknown[2:4, ] <- NA

	rec <- recipes::recipe(mpg ~ ., data = mtcars_unknown) %>%
		recipes::step_unknown(recipes::all_nominal_predictors()) %>%
		recipes::prep(strings_as_factors = FALSE)

	res <- dplyr::mutate(mtcars_unknown, !!!orbital_inline(orbital(rec)))

	sc <- testthat_spark_connection()
	mtcars_tbl <- testthat_tbl("mtcars_unknown")

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)
})

test_that("SQLite - step_unknown works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("DBI")
	skip_if_not_installed("RSQLite")

	mtcars_unknown <- dplyr::as_tibble(mtcars)
	mtcars_unknown$gear <- letters[mtcars$gear]
	mtcars_unknown$carb <- letters[mtcars$carb]
	mtcars_unknown[2:4, ] <- NA

	rec <- recipes::recipe(mpg ~ ., data = mtcars_unknown) %>%
		recipes::step_unknown(recipes::all_nominal_predictors()) %>%
		recipes::prep(strings_as_factors = FALSE)

	res <- dplyr::mutate(mtcars_unknown, !!!orbital_inline(orbital(rec)))

	con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
	mtcars_tbl <- dplyr::copy_to(con, mtcars_unknown)

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)

	DBI::dbDisconnect(con)
})

test_that("duckdb - step_unknown works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("DBI")
	skip_if_not_installed("duckdb")

	mtcars_unknown <- dplyr::as_tibble(mtcars)
	mtcars_unknown$gear <- letters[mtcars$gear]
	mtcars_unknown$carb <- letters[mtcars$carb]
	mtcars_unknown[2:4, ] <- NA

	rec <- recipes::recipe(mpg ~ ., data = mtcars_unknown) %>%
		recipes::step_unknown(recipes::all_nominal_predictors()) %>%
		recipes::prep(strings_as_factors = FALSE)

	res <- dplyr::mutate(mtcars_unknown, !!!orbital_inline(orbital(rec)))

	con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
	mtcars_tbl <- dplyr::copy_to(con, mtcars_unknown)

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)

	DBI::dbDisconnect(con)
})

test_that("arrow - step_unknown works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("arrow")

	mtcars_unknown <- dplyr::as_tibble(mtcars)
	mtcars_unknown$gear <- letters[mtcars$gear]
	mtcars_unknown$carb <- letters[mtcars$carb]
	mtcars_unknown[2:4, ] <- NA

	rec <- recipes::recipe(mpg ~ ., data = mtcars_unknown) %>%
		recipes::step_unknown(recipes::all_nominal_predictors()) %>%
		recipes::prep(strings_as_factors = FALSE)

	res <- dplyr::mutate(mtcars_unknown, !!!orbital_inline(orbital(rec)))

	mtcars_tbl <- arrow::as_arrow_table(mtcars_unknown)

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)
})
