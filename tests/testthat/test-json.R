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

	# temp fix
	attr(orbital_obj, "pred_names") <- NULL

	expect_identical(new, orbital_obj)
})
