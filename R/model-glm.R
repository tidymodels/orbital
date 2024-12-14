#' @export
orbital.glm <- function(x, ..., mode = c("classification", "regression")) {
	mode <- rlang::arg_match(mode)

	if (mode == "classification") {
		levels <- levels(x$model$Species)
		levels <- glue::double_quote(levels)
		res <- tidypredict::tidypredict_fit(x)
		res <- deparse1(res)
		res <- glue::glue(
			"dplyr::case_when({res} < 0.5 ~ {levels[1]}, .default = {levels[2]})"
		)
	} else if (mode == "regression") {
		res <- tidypredict::tidypredict_fit(x)
	}
	res
}
