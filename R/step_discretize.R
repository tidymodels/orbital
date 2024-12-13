#' @export
orbital.step_discretize <- function(x, all_vars, ...) {
	out <- character()

	x$objects <- x$objects[names(x$objects) %in% all_vars]

	for (i in seq_along(x$objects)) {
		object <- x$objects[[i]]
		if (object$bins == 0) {
			next
		}

		col <- names(x$objects)[i]

		eq <- character()

		if (object$keep_na) {
			eq <- c(eq, glue::glue("is.na({col})"))
		}

		eq <- c(eq, glue::glue("{col} < {object$breaks[2]}"))
		if (object$bins > 2) {
			low <- seq(2, object$bins - 1)
			high <- low + 1

			eq <- c(
				eq,
				glue::glue(
					"{object$breaks[low]} < {col} & {col} <= {object$breaks[high]}"
				)
			)
		}
		if (object$bins != 1) {
			eq <- c(eq, glue::glue("{utils::tail(object$breaks, 2)[1]} <= {col}"))
		}

		eq <- glue::glue("{eq} ~ \"{object$prefix}{object$labels}\"")
		eq <- paste(eq, collapse = ", ")
		eq <- glue::glue("dplyr::case_when({eq})")

		names(eq) <- col
		out <- c(out, eq)
	}

	out
}
