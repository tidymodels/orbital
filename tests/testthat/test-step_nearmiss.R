test_that("step_nearmiss works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("themis")

	mtcars <- dplyr::as_tibble(mtcars)
	mtcars$vs <- as.factor(mtcars$vs)

	rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
		themis::step_nearmiss(vs, skip = TRUE) %>%
		recipes::prep()

	res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

	exp <- recipes::bake(rec, new_data = mtcars)
	exp <- exp[names(res)]

	expect_equal(res, exp)
})

test_that("step_nearmiss errors with skip = FALSE", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("themis")

	mtcars <- dplyr::as_tibble(mtcars)
	mtcars$vs <- as.factor(mtcars$vs)

	rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
		themis::step_nearmiss(vs, skip = FALSE) %>%
		recipes::prep()

	expect_snapshot(
		error = TRUE,
		orbital(rec)
	)
})

test_that("step_nearmiss only calculates what is sufficient", {
	# Here for completeness
	# step_nearmiss() doesn't work with empty selections
	# as it is a resampling step

	expect_true(TRUE)
})

test_that("step_nearmiss works with empty selections", {
	# Here for completeness
	# step_nearmiss() doesn't work with empty selections
	# as it is a resampling step

	expect_true(TRUE)
})

test_that("spark - step_nearmiss works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("themis")
	skip_if_not_installed("sparklyr")
	skip_if(is.na(testthat_spark_env_version()))

	mtcars_nearmiss <- dplyr::as_tibble(mtcars)
	mtcars_nearmiss$vs <- as.factor(mtcars$vs)

	rec <- recipes::recipe(mpg ~ ., data = mtcars_nearmiss) %>%
		themis::step_nearmiss(vs, skip = TRUE) %>%
		recipes::prep()

	res <- dplyr::mutate(mtcars_nearmiss, !!!orbital_inline(orbital(rec)))
	res$vs <- as.character(res$vs)

	sc <- testthat_spark_connection()
	mtcars_tbl <- testthat_tbl("mtcars_nearmiss")

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)
})

test_that("SQLite - step_nearmiss works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("themis")
	skip_if_not_installed("DBI")
	skip_if_not_installed("RSQLite")
	skip_on_cran()

	mtcars_nearmiss <- dplyr::as_tibble(mtcars)
	mtcars_nearmiss$vs <- as.factor(mtcars$vs)

	rec <- recipes::recipe(mpg ~ ., data = mtcars_nearmiss) %>%
		themis::step_nearmiss(vs, skip = TRUE) %>%
		recipes::prep()

	res <- dplyr::mutate(mtcars_nearmiss, !!!orbital_inline(orbital(rec)))
	res$vs <- as.character(res$vs)

	con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
	mtcars_tbl <- dplyr::copy_to(con, mtcars_nearmiss)

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)

	DBI::dbDisconnect(con)
})

test_that("duckdb - step_nearmiss works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("themis")
	skip_if_not_installed("DBI")
	skip_if_not_installed("duckdb")

	mtcars_nearmiss <- dplyr::as_tibble(mtcars)
	mtcars_nearmiss$vs <- as.factor(mtcars$vs)

	rec <- recipes::recipe(mpg ~ ., data = mtcars_nearmiss) %>%
		themis::step_nearmiss(vs, skip = TRUE) %>%
		recipes::prep()

	res <- dplyr::mutate(mtcars_nearmiss, !!!orbital_inline(orbital(rec)))

	con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
	mtcars_tbl <- dplyr::copy_to(con, mtcars_nearmiss)

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)

	DBI::dbDisconnect(con)
})

test_that("arrow - step_nearmiss works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("themis")
	skip_if_not_installed("arrow")

	mtcars_nearmiss <- dplyr::as_tibble(mtcars)
	mtcars_nearmiss$vs <- as.factor(mtcars$vs)

	rec <- recipes::recipe(mpg ~ ., data = mtcars_nearmiss) %>%
		themis::step_nearmiss(vs, skip = TRUE) %>%
		recipes::prep()

	res <- dplyr::mutate(mtcars_nearmiss, !!!orbital_inline(orbital(rec)))

	mtcars_tbl <- arrow::as_arrow_table(mtcars_nearmiss)

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)
})
