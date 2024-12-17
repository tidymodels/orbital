#' @export
orbital.glm <- function(
	x,
	...,
	mode = c("classification", "regression"),
	type = NULL
) {
	mode <- rlang::arg_match(mode)
	type <- default_type(type)

	if (mode == "classification") {
		outcome <- names(attr(x$terms, "dataClasses"))[attr(x$terms, "response")]
		levels <- levels(x$data[[outcome]])
		levels <- glue::double_quote(levels)
		eq <- tidypredict::tidypredict_fit(x)
		eq <- deparse1(eq)

		res <- NULL
		if ("class" %in% type) {
			res <- c(
				res,
				orbital_tmp_class_name = glue::glue(
					"dplyr::case_when({eq} < 0.5 ~ {levels[1]}, .default = {levels[2]})"
				)
			)
		}
		if ("prob" %in% type) {
			res <- c(
				res,
				orbital_tmp_prob_name1 = glue::glue("1 - ({eq})"),
				orbital_tmp_prob_name2 = glue::glue("{eq}")
			)
		}
	} else if (mode == "regression") {
		res <- tidypredict::tidypredict_fit(x)
	}
	res
}
