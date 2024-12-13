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

test_that("step_novel only calculates what is sufficient", {
	skip_if_not_installed("recipes")

	mtcars <- dplyr::as_tibble(mtcars)
	mtcars[2:4, ] <- NA
	mtcars$gear <- letters[mtcars$gear]
	mtcars$carb <- letters[mtcars$carb]

	rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
		recipes::step_novel(recipes::all_nominal_predictors()) %>%
		recipes::step_rm(gear) %>%
		recipes::prep(strings_as_factors = FALSE)

	expect_identical(
		names(orbital(rec)),
		"carb"
	)
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

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)
})

test_that("SQLite - step_novel works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("DBI")
	skip_if_not_installed("RSQLite")

	mtcars_novel <- dplyr::as_tibble(mtcars)
	mtcars_novel$gear <- letters[mtcars$gear]
	mtcars_novel$carb <- letters[mtcars$carb]
	mtcars_novel[2:4, ] <- NA

	rec <- recipes::recipe(mpg ~ ., data = mtcars_novel) %>%
		recipes::step_novel(recipes::all_nominal_predictors()) %>%
		recipes::prep()

	mtcars_novel[1, 10] <- "aaaaa"

	res <- dplyr::mutate(mtcars_novel, !!!orbital_inline(orbital(rec)))

	con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
	mtcars_tbl <- dplyr::copy_to(con, mtcars_novel)

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)

	DBI::dbDisconnect(con)
})

test_that("duckdb - step_novel works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("DBI")
	skip_if_not_installed("duckdb")

	mtcars_novel <- dplyr::as_tibble(mtcars)
	mtcars_novel$gear <- letters[mtcars$gear]
	mtcars_novel$carb <- letters[mtcars$carb]
	mtcars_novel[2:4, ] <- NA

	rec <- recipes::recipe(mpg ~ ., data = mtcars_novel) %>%
		recipes::step_novel(recipes::all_nominal_predictors()) %>%
		recipes::prep()

	mtcars_novel[1, 10] <- "aaaaa"

	res <- dplyr::mutate(mtcars_novel, !!!orbital_inline(orbital(rec)))

	con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
	mtcars_tbl <- dplyr::copy_to(con, mtcars_novel)

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)

	DBI::dbDisconnect(con)
})

test_that("arrow - step_novel works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("arrow")

	mtcars_novel <- dplyr::as_tibble(mtcars)
	mtcars_novel$gear <- letters[mtcars$gear]
	mtcars_novel$carb <- letters[mtcars$carb]
	mtcars_novel[2:4, ] <- NA

	rec <- recipes::recipe(mpg ~ ., data = mtcars_novel) %>%
		recipes::step_novel(recipes::all_nominal_predictors()) %>%
		recipes::prep()

	mtcars_novel[1, 10] <- "aaaaa"

	res <- dplyr::mutate(mtcars_novel, !!!orbital_inline(orbital(rec)))

	mtcars_tbl <- arrow::as_arrow_table(mtcars_novel)

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)
})
