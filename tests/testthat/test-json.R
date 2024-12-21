test_that("read and write json works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("tidypredict")
	skip_if_not_installed("jsonlite")
	skip_if_not_installed("workflows")
	rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
		recipes::step_normalize(recipes::all_numeric_predictors())

	lm_spec <- parsnip::linear_reg()

	wf_spec <- workflows::workflow(rec_spec, lm_spec)

	wf_fit <- parsnip::fit(wf_spec, mtcars)

	orbital_obj <- orbital(wf_fit)

	tmp_file <- tempfile()

	orbital_json_write(orbital_obj, tmp_file)

	new <- orbital_json_read(tmp_file)

	expect_identical(new, orbital_obj)
})

test_that("read and write json works - backwards from version 1", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("tidypredict")
	skip_if_not_installed("jsonlite")
	skip_if_not_installed("workflows")
	rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
		recipes::step_normalize(recipes::all_numeric_predictors())

	lm_spec <- parsnip::linear_reg()

	wf_spec <- workflows::workflow(rec_spec, lm_spec)

	wf_fit <- parsnip::fit(wf_spec, mtcars)

	orbital_obj <- orbital(wf_fit)

	tmp_file <- tempfile()
	
	orbital_json_write(orbital_obj, tmp_file)

	# Fake version 1
	fake_json <- jsonlite::read_json(tmp_file)
	fake_json$pred_names <- NULL
	fake_json$version <- 1
	fake_json <- jsonlite::toJSON(fake_json, pretty = TRUE, auto_unbox = TRUE)
	writeLines(fake_json, tmp_file)

	new <- orbital_json_read(tmp_file)

	expect_identical(new, orbital_obj)
})
