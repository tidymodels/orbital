test_that("multiplication works", {
	skip_if_not_installed("parsnip")
	skip_if_not_installed("tidypredict")

	mtcars$vs <- factor(mtcars$vs)

	lr_spec <- parsnip::logistic_reg()

	lr_fit <- parsnip::fit(lr_spec, vs ~ disp + mpg + hp, mtcars)

	orb_obj <- orbital(lr_fit)

	preds <- predict(orb_obj, mtcars)
	exps <- predict(lr_fit, mtcars)

	expect_named(preds, ".pred_class")
	expect_type(preds$.pred_class, "character")

	expect_identical(
		preds$.pred_class,
		as.character(exps$.pred_class)
	)
})
