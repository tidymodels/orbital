#' @export
orbital.model_fit <- function(x, ..., prefix = ".pred") {
	mode <- x$spec$mode

	check_mode(mode)

	res <- try(orbital(x$fit, mode = mode), silent = TRUE)

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

	if (mode == "classification") {
		prefix <- paste0(prefix, "_class")
	}

	if (is.language(res)) {
		res <- deparse1(res)
	}

	res <- stats::setNames(res, prefix)

	new_orbital_class(res)
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
