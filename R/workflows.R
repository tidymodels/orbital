#' @export
orbital.workflow <- function(x, ..., prefix = ".pred", type = NULL) {
	if (!workflows::is_trained_workflow(x)) {
		cli::cli_abort("{.arg x} must be a fully trained {.cls workflow}.")
	}

	if (length(x$post$actions) != 0) {
		cli::cli_abort("post-processing is not yet supported in orbital.")
	}

	model_fit <- workflows::extract_fit_parsnip(x)
	out <- orbital(model_fit, prefix = prefix, type = type)

	preprocessor <- workflows::extract_preprocessor(x)

	if (inherits(preprocessor, "recipe")) {
		recipe_fit <- workflows::extract_recipe(x)

		pred_names <- attr(out, "pred_names")
		out <- orbital(recipe_fit, out, prefix = prefix)
		attr(out, "pred_names") <- pred_names
	}

	new_orbital_class(out)
}
