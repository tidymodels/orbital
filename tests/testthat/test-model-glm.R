test_that("logistic_reg() works with type = class", {
	skip_if_not_installed("parsnip")
	skip_if_not_installed("tidypredict")

	mtcars$vs <- factor(mtcars$vs)

	lr_spec <- parsnip::logistic_reg()

	lr_fit <- parsnip::fit(lr_spec, vs ~ disp + mpg + hp, mtcars)

	orb_obj <- orbital(lr_fit, type = "class")

	preds <- predict(orb_obj, mtcars)
	exps <- predict(lr_fit, mtcars)

	expect_named(preds, ".pred_class")
	expect_type(preds$.pred_class, "character")

	expect_identical(
		preds$.pred_class,
		as.character(exps$.pred_class)
	)
})

test_that("logistic_reg() works with type = prob", {
	skip_if_not_installed("parsnip")
	skip_if_not_installed("tidypredict")

	mtcars$vs <- factor(mtcars$vs)

	lr_spec <- parsnip::logistic_reg()

	lr_fit <- parsnip::fit(lr_spec, vs ~ disp + mpg + hp, mtcars)

	orb_obj <- orbital(lr_fit, type = "prob")

	preds <- predict(orb_obj, mtcars)
	exps <- predict(lr_fit, mtcars, type = "prob")

	expect_named(preds, c(".pred_0", ".pred_1"))
	expect_type(preds$.pred_0, "double")
	expect_type(preds$.pred_1, "double")

	exps <- as.data.frame(exps)

	rownames(preds) <- NULL
	rownames(exps) <- NULL

	expect_equal(
		preds,
		exps
	)
})
