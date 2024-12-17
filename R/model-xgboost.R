#' @export
orbital.xgb.Booster <- function(
	x,
	...,
	mode = c("classification", "regression"),
	type = NULL,
	lvl = NULL
) {
	mode <- rlang::arg_match(mode)

	if (mode == "classification") {
		objective <- x$params$objective
		objective <- rlang::arg_match0(
			objective,
			c("multi:softprob", "binary:logistic")
		)

		if (is.null(type)) {
			type <- "class"
		}

		extractor <- switch(
			objective,
			"multi:softprob" = xgboost_multisoft,
			"binary:logistic" = xgboost_logistic
		)

		res <- extractor(x, type, lvl)
	} else if (mode == "regression") {
		res <- tidypredict::tidypredict_fit(x)
	}
	res
}

xgboost_multisoft <- function(x, type, lvl) {
	trees <- tidypredict::.extract_xgb_trees(x)

	trees_split <- split(trees, rep(seq_along(lvl), x$niter))
	trees_split <- vapply(trees_split, paste, character(1), collapse = " + ")
	trees_split <- namespace_case_when(trees_split)

	res <- stats::setNames(trees_split, lvl)

	if ("class" %in% type) {
		res <- c(
			res,
			".pred_class" = softmax(lvl)
		)
	}
	if ("prob" %in% type) {
		res <- c(
			res,
			"norm" = glue::glue_collapse(glue::glue("exp({lvl})"), sep = " + "),
			stats::setNames(glue::glue("exp({lvl}) / norm"), NA)
		)
	}
	res
}

xgboost_logistic <- function(x, type, lvl) {
	eq <- tidypredict::tidypredict_fit(x)

	eq <- deparse1(eq)
	eq <- namespace_case_when(eq)

	res <- NULL
	if ("class" %in% type) {
		levels <- glue::double_quote(lvl)

		res <- c(
			res,
			.pred_class = glue::glue(
				"dplyr::case_when({eq} > 0.5 ~ {levels[1]}, .default = {levels[2]})"
			)
		)
	}
	if ("prob" %in% type) {
		res <- c(
			res,
			glue::glue("{eq}"),
			glue::glue("1 - ({eq})")
		)
	}
	res
}

namespace_case_when <- function(x) {
	x <- gsub("dplyr::case_when", "case_when", x)
	x <- gsub("case_when", "dplyr::case_when", x)
	x
}

softmax <- function(lvl) {
	res <- character(0)

	for (i in seq(1, length(lvl) - 1)) {
		line <- glue::glue("{lvl[i]} > {lvl[-i]}")
		line <- glue::glue_collapse(line, sep = " & ")
		line <- glue::glue("{line} ~ {glue::double_quote(lvl[i])}")
		res[i] <- line
	}

	res <- glue::glue_collapse(res, ", ")
	default <- glue::double_quote(lvl[length(lvl)])

	glue::glue("dplyr::case_when({res}, .default = {default})")
}
