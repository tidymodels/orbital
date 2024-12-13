#' @export
orbital.step_lag <- function(x, all_vars, ...) {
	if (length(x$columns) == 0) {
		return(NULL)
	}

	configs <- expand.grid(lag = x$lag, columns = x$columns)
	col_names <- glue::glue("{x$prefix}{configs$lag}_{configs$columns}")

	used_vars <- col_names %in% all_vars
	configs <- configs[used_vars, ]
	col_names <- col_names[used_vars]

	out <- glue::glue(
		"dplyr::lag({configs$columns}, {configs$lag}, default = {x$default})"
	)

	names(out) <- col_names
	out
}
