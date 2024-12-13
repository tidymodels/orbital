test_that("step_upsample works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("themis")

	mtcars <- dplyr::as_tibble(mtcars)
	mtcars$vs <- as.factor(mtcars$vs)

	rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
		themis::step_upsample(vs, skip = TRUE) %>%
		recipes::prep()

	res <- dplyr::mutate(mtcars, !!!orbital_inline(orbital(rec)))

	exp <- recipes::bake(rec, new_data = mtcars)
	exp <- exp[names(res)]

	expect_equal(res, exp)
})

test_that("step_upsample errors with skip = FALSE", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("themis")

	mtcars <- dplyr::as_tibble(mtcars)
	mtcars$vs <- as.factor(mtcars$vs)

	rec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
		themis::step_upsample(vs, skip = FALSE) %>%
		recipes::prep()

	expect_snapshot(
		error = TRUE,
		orbital(rec)
	)
})

test_that("step_upsample only calculates what is sufficient", {
	# Here for completeness
	# step_upsample() doesn't work with empty selections
	# as it is a resampling step

	expect_true(TRUE)
})

test_that("step_upsample works with empty selections", {
	# Here for completeness
	# step_upsample() doesn't work with empty selections
	# as it is a resampling step

	expect_true(TRUE)
})

test_that("spark - step_upsample works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("themis")
	skip_if_not_installed("sparklyr")
	skip_if(is.na(testthat_spark_env_version()))

	mtcars_upsample <- dplyr::as_tibble(mtcars)
	mtcars_upsample$vs <- as.factor(mtcars$vs)

	rec <- recipes::recipe(mpg ~ ., data = mtcars_upsample) %>%
		themis::step_upsample(vs, skip = TRUE) %>%
		recipes::prep()

	res <- dplyr::mutate(mtcars_upsample, !!!orbital_inline(orbital(rec)))
	res$vs <- as.character(res$vs)

	sc <- testthat_spark_connection()
	mtcars_tbl <- testthat_tbl("mtcars_upsample")

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)
})

test_that("SQLite - step_upsample works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("themis")
	skip_if_not_installed("DBI")
	skip_if_not_installed("RSQLite")

	mtcars_upsample <- dplyr::as_tibble(mtcars)
	mtcars_upsample$vs <- as.factor(mtcars$vs)

	rec <- recipes::recipe(mpg ~ ., data = mtcars_upsample) %>%
		themis::step_upsample(vs, skip = TRUE) %>%
		recipes::prep()

	res <- dplyr::mutate(mtcars_upsample, !!!orbital_inline(orbital(rec)))
	res$vs <- as.character(res$vs)

	con <- DBI::dbConnect(RSQLite::SQLite(), path = ":memory:")
	mtcars_tbl <- dplyr::copy_to(con, mtcars_upsample)

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)

	DBI::dbDisconnect(con)
})

test_that("duckdb - step_upsample works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("themis")
	skip_if_not_installed("DBI")
	skip_if_not_installed("duckdb")

	mtcars_upsample <- dplyr::as_tibble(mtcars)
	mtcars_upsample$vs <- as.factor(mtcars$vs)

	rec <- recipes::recipe(mpg ~ ., data = mtcars_upsample) %>%
		themis::step_upsample(vs, skip = TRUE) %>%
		recipes::prep()

	res <- dplyr::mutate(mtcars_upsample, !!!orbital_inline(orbital(rec)))

	con <- DBI::dbConnect(duckdb::duckdb(dbdir = ":memory:"))
	mtcars_tbl <- dplyr::copy_to(con, mtcars_upsample)

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)

	DBI::dbDisconnect(con)
})

test_that("arrow - step_upsample works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("themis")
	skip_if_not_installed("arrow")

	mtcars_upsample <- dplyr::as_tibble(mtcars)
	mtcars_upsample$vs <- as.factor(mtcars$vs)

	rec <- recipes::recipe(mpg ~ ., data = mtcars_upsample) %>%
		themis::step_upsample(vs, skip = TRUE) %>%
		recipes::prep()

	res <- dplyr::mutate(mtcars_upsample, !!!orbital_inline(orbital(rec)))

	mtcars_tbl <- arrow::as_arrow_table(mtcars_upsample)

	res_new <- dplyr::mutate(mtcars_tbl, !!!orbital_inline(orbital(rec))) %>%
		dplyr::collect()

	expect_equal(res_new, res)
})
