#' @export
orbital.model_fit <- function(x, ..., prefix = ".pred", type = NULL) {
	mode <- x$spec$mode
	check_mode(mode)
	check_type(type, mode)
	type <- default_type(type)

	res <- try(
		orbital(x$fit, mode = mode, type = type, lvl = x$lvl),
		silent = TRUE
	)

	if (inherits(res, "try-error")) {
		res <- tryCatch(
			tidypredict::tidypredict_fit(x),
			error = function(cnd) {
				if (grepl("no applicable method for", cnd$message)) {
					cls <- class(x)
					cls <- setdiff(cls, "model_fit")
					cls <- gsub("^_", "", cls)

					cli::cli_abort(
						"A model of class {.cls {cls}} is not supported.",
						call = rlang::call2("orbital")
					)
				}
				stop(cnd)
			}
		)
	}

	if (is.language(res)) {
		res <- deparse1(res)
	}

	res <- namespace_case_when(res)
	res <- set_pred_names(res, x, mode, type, prefix)

	new_orbital_class(res)
}

set_pred_names <- function(res, x, mode, type, prefix) {
	if (mode == "regression") {
		res <- stats::setNames(res, prefix)
		attr(res, "pred_names") <- prefix
	}

	if (mode == "classification") {
		class_names <- NULL
		prob_names <- NULL

		if ("class" %in% type) {
			class_names <- paste0(prefix, "_class")
		}
		if ("prob" %in% type) {
			prob_names <- paste0(prefix, "_", x$lvl)
		}

		attr(res, "pred_names") <- c(class_names, prob_names)

		eq_names <- names(res)

		class_ind <- eq_names %in% "orbital_tmp_class_name"
		prob_ind <- grepl("^orbital_tmp_prob_name", eq_names)

		eq_names[class_ind] <- class_names
		eq_names[prob_ind] <- prob_names

		names(res) <- eq_names
	}

	res
}

#' @export
orbital.model_spec <- function(x, ...) {
	cli::cli_abort("{.arg x} must be fitted model.")
}

check_mode <- function(mode, call = rlang::caller_env()) {
	supported_modes <- c("regression", "classification")

	if (!(mode %in% supported_modes)) {
		cli::cli_abort(
			"Only models with modes {.val {supported_modes}} are supported. 
      Not {.val {mode}}.",
			call = call
		)
	}
}

check_type <- function(type, mode, call = rlang::caller_env()) {
	if (is.null(type)) {
		return(invisible())
	}

	supported_types <- c("numeric", "class", "prob")
	rlang::arg_match(type, supported_types, multiple = TRUE, error_call = call)

	if (mode == "regression" && any(!type %in% "numeric")) {
		cli::cli_abort(
			"{.arg type} can only be {.val numeric} for model with mode 
			{.val regression}, not {.val {type}}.",
			call = call
		)
	}
	if (mode == "classification" && any(!type %in% c("class", "prob"))) {
		cli::cli_abort(
			"{.arg type} can only be {.val class} or {.val prob} for model with mode 
			{.val classification}, not {.val {type}}.",
			call = call
		)
	}
}

default_type <- function(type) {
	if (is.null(type)) {
		type <- "class"
	}

	type
}
