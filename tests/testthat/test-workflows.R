test_that("type argument checking works", {
	skip_if_not_installed("tidypredict")
	skip_if_not_installed("workflows")
	lm_spec <- parsnip::linear_reg()

	wf_spec <- workflows::workflow() %>%
		workflows::add_variables(outcomes = "mpg", predictors = everything()) %>%
		workflows::add_model(lm_spec)

	wf_fit <- parsnip::fit(wf_spec, mtcars)

	expect_no_error(
		orbital(wf_fit, type = "numeric")
	)

	expect_snapshot(
		error = TRUE,
		orbital(wf_fit, type = "invalid")
	)
	expect_snapshot(
		error = TRUE,
		orbital(wf_fit, type = "class")
	)
	expect_snapshot(
		error = TRUE,
		orbital(wf_fit, type = c("class", "numeric"))
	)

	lr_spec <- parsnip::logistic_reg()

	mtcars$vs <- factor(mtcars$vs)

	wf_spec <- workflows::workflow() %>%
		workflows::add_variables(outcomes = "vs", predictors = "disp") %>%
		workflows::add_model(lr_spec)

	wf_fit <- parsnip::fit(wf_spec, mtcars)

	expect_no_error(
		orbital(wf_fit, type = "class")
	)

	expect_no_error(
		orbital(wf_fit, type = c("class", "prob"))
	)

	expect_snapshot(
		error = TRUE,
		orbital(wf_fit, type = "invalid")
	)
	expect_snapshot(
		error = TRUE,
		orbital(wf_fit, type = "numeric")
	)
	expect_snapshot(
		error = TRUE,
		orbital(wf_fit, type = c("class", "numeric"))
	)
})
