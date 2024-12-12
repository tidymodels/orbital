test_that("step_zv works", {
	skip_if_not_installed("recipes")

	mtcars0 <- mtcars
	mtcars0$zv <- 0

	rec_exp <- recipes::recipe(mpg ~ ., data = mtcars) %>%
		recipes::step_zv(recipes::all_predictors()) %>%
		recipes::prep()

	expect_null(orbital(rec_exp$steps[[1]]))

	rec <- recipes::recipe(mpg ~ ., data = mtcars0) %>%
		recipes::step_zv(recipes::all_predictors()) %>%
		recipes::prep()

	expect_null(orbital(rec$steps[[1]]))

	expect_identical(orbital(rec), orbital(rec_exp))
})

test_that("step_zv only calculates what is sufficient", {
	# Isn't needed as `step_zv()` doesn't produce code
	expect_true(TRUE)
})

test_that("step_zv works with empty selections", {
	# Isn't needed as `step_zv()` doesn't produce code
	expect_true(TRUE)
})

test_that("spark - step_zv works", {
	# Isn't needed as `step_zv()` doesn't produce code
	expect_true(TRUE)
})

test_that("SQLite - step_zv works", {
	# Isn't needed as `step_zv()` doesn't produce code
	expect_true(TRUE)
})

test_that("duckdb - step_zv works", {
	# Isn't needed as `step_zv()` doesn't produce code
	expect_true(TRUE)
})

test_that("arrow - step_zv works", {
	# Isn't needed as `step_zv()` doesn't produce code
	expect_true(TRUE)
})
