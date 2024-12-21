test_that("decision_tree(partykit) works with type = class", {
	skip_if_not_installed("parsnip")
	skip_if_not_installed("tidypredict")
	skip_if_not_installed("bonsai")
	library(bonsai)

	mtcars$vs <- factor(mtcars$vs)

	lr_spec <- parsnip::decision_tree("classification", "partykit")

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

test_that("decision_tree(partykit) works with type = prob", {
	skip_if_not_installed("parsnip")
	skip_if_not_installed("tidypredict")
	skip_if_not_installed("bonsai")
	library(bonsai)

	mtcars$vs <- factor(mtcars$vs)

	lr_spec <- parsnip::decision_tree("classification", "partykit")

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

test_that("decision_tree(partykit) works with type = c(class, prob)", {
	skip_if_not_installed("parsnip")
	skip_if_not_installed("tidypredict")
	skip_if_not_installed("bonsai")
	library(bonsai)

	mtcars$vs <- factor(mtcars$vs)

	lr_spec <- parsnip::decision_tree("classification", "partykit")

	lr_fit <- parsnip::fit(lr_spec, vs ~ disp + mpg + hp, mtcars)

	orb_obj <- orbital(lr_fit, type = c("class", "prob"))

	preds <- predict(orb_obj, mtcars)
	exps <- dplyr::bind_cols(
		predict(lr_fit, mtcars, type = c("class")),
		predict(lr_fit, mtcars, type = c("prob"))
	)

	expect_named(preds, c(".pred_class", ".pred_0", ".pred_1"))
	expect_type(preds$.pred_class, "character")
	expect_type(preds$.pred_0, "double")
	expect_type(preds$.pred_1, "double")

	exps <- as.data.frame(exps)
	exps$.pred_class <- as.character(exps$.pred_class)

	rownames(preds) <- NULL
	rownames(exps) <- NULL

	expect_equal(
		preds,
		exps
	)
})
