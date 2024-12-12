#' @export
orbital.step_ratio <- function(x, all_vars, ...) {
	columns <- x$columns

	if (nrow(columns) == 0) {
		return(NULL)
	}

	col_names <- x$naming(columns$top, columns$bottom)

	used_vars <- col_names %in% all_vars
	columns <- columns[used_vars, ]
	col_names <- col_names[used_vars]

	out <- glue::glue("{columns$top} / {columns$bottom}")
	names(out) <- col_names
	out
}
