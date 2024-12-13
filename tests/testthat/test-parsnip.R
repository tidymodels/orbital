test_that("normal usage works works", {
	skip_if_not_installed("recipes")
	skip_if_not_installed("parsnip")
	skip_if_not_installed("workflows")
	skip_if_not_installed("tidypredict")
	skip_if_not_installed("kknn")

	rec_spec <- recipes::recipe(mpg ~ ., data = mtcars) %>%
		recipes::step_normalize(recipes::all_numeric_predictors())

	lm_spec <- parsnip::nearest_neighbor(mode = "regression")

	wf_spec <- workflows::workflow(rec_spec, lm_spec)

	wf_fit <- parsnip::fit(wf_spec, mtcars)

	expect_snapshot(
		error = TRUE,
		orbital(wf_fit)
	)
})

test_that("prefix argument works", {
	skip_if_not_installed("parsnip")
	skip_if_not_installed("tidypredict")

	lm_spec <- parsnip::linear_reg()

	lm_fit <- parsnip::fit(lm_spec, mpg ~ ., mtcars)

	orb_obj <- orbital(lm_fit, prefix = "pred")

	expect_true("pred" %in% names(orb_obj))
	expect_false(".pred" %in% names(orb_obj))
})
