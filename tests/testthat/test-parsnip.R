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

	lr_spec <- parsnip::logistic_reg()

	mtcars$vs <- factor(mtcars$vs)

	lr_fit <- parsnip::fit(lr_spec, vs ~ disp, mtcars)

	orb_obj <- orbital(lr_fit, prefix = "pred")

	expect_true("pred_class" %in% names(orb_obj))
	expect_false(".pred_class" %in% names(orb_obj))
})

test_that("errors on invalid modes", {
	skip_if_not_installed("parsnip")

	lm_spec <- parsnip::linear_reg()

	lm_fit <- parsnip::fit(lm_spec, mpg ~ ., mtcars)

	lm_fit$spec$mode <- "invalid mode"

	expect_snapshot(
		error = TRUE,
		orbital(lm_fit)
	)
})

test_that("type argument checking works", {
	skip_if_not_installed("tidypredict")
	lm_spec <- parsnip::linear_reg()

	lm_fit <- parsnip::fit(lm_spec, mpg ~ ., mtcars)

	expect_no_error(
		orbital(lm_fit, type = "numeric")
	)

	expect_snapshot(
		error = TRUE,
		orbital(lm_fit, type = "invalid")
	)
	expect_snapshot(
		error = TRUE,
		orbital(lm_fit, type = "class")
	)
	expect_snapshot(
		error = TRUE,
		orbital(lm_fit, type = c("class", "numeric"))
	)

	lm_spec <- parsnip::logistic_reg()

	mtcars$vs <- factor(mtcars$vs)

	lm_fit <- parsnip::fit(lm_spec, vs ~ disp, mtcars)

	expect_no_error(
		orbital(lm_fit, type = "class")
	)

	expect_no_error(
		orbital(lm_fit, type = c("class", "prob"))
	)

	expect_snapshot(
		error = TRUE,
		orbital(lm_fit, type = "invalid")
	)
	expect_snapshot(
		error = TRUE,
		orbital(lm_fit, type = "numeric")
	)
	expect_snapshot(
		error = TRUE,
		orbital(lm_fit, type = c("class", "numeric"))
	)
})
