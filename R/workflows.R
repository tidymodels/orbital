#' @export
orbital.workflow <- function(x, ..., prefix = ".pred") {
	if (!workflows::is_trained_workflow(x)) {
		cli::cli_abort("{.arg x} must be a fully trained {.cls workflow}.")
	}

	if (length(x$post$actions) != 0) {
		cli::cli_abort("post-processing is not yet supported in orbital.")
	}

	model_fit <- workflows::extract_fit_parsnip(x)
	out <- orbital(model_fit, prefix = prefix)

	preprocessor <- workflows::extract_preprocessor(x)

	if (inherits(preprocessor, "recipe")) {
		recipe_fit <- workflows::extract_recipe(x)

		out <- orbital(recipe_fit, out, prefix = prefix)
	}

	new_orbital_class(out)
}
