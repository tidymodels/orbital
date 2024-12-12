#' @export
orbital.step_inverse <- function(x, all_vars, ...) {
	offset <- x$offset
	columns <- x$columns

	columns <- columns[columns %in% all_vars]

	if (length(columns) == 0) {
		return(NULL)
	}

	if (offset == 0) {
		out <- glue::glue("1 / {columns}")
	} else {
		out <- glue::glue("1 / ({columns} + {offset})")
	}

	names(out) <- names(columns)
	out
}
