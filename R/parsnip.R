#' @export
orbital.model_fit <- function(x, ..., prefix = ".pred", type = NULL) {
	mode <- x$spec$mode
	check_mode(mode)
	check_type(type, mode)

	if (mode == "classification") {
		res <- try(
			orbital(x$fit, mode = mode, type = type, lvl = x$lvl),
			silent = TRUE
		)
	} else {
		res <- try(orbital(x$fit, mode = mode, type = type), silent = TRUE)
	}

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
		names <- NULL

		if (is.null(type)) {
			type <- "class"
		}

		if ("class" %in% type) {
			names <- c(names, paste0(prefix, "_class"))
		}
		if ("prob" %in% type) {
			names <- c(names, paste0(prefix, "_", x$lvl))
		}
	}
	if (mode == "regression") {
		names <- prefix
	}

	if (is.language(res)) {
		res <- deparse1(res)
	}

	attr(res, "pred_names") <- names
	if (
		inherits(x, "_xgb.Booster") &&
			isTRUE(x$fit$params$objective == "multi:softprob")
	) {
		if (anyNA(names(res))) {
			na_fields <- which(is.na(names(res)))
			tmp_names <- names(res)
			tmp_names[na_fields] <- paste0(prefix, "_", x$lvl)
			names(res) <- tmp_names
		}
	} else {
		res <- stats::setNames(res, names)
	}

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
