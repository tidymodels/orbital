#' @export
orbital.step_range <- function(x, all_vars, ...) {
	ranges <- x$ranges

	used_vars <- colnames(ranges) %in% all_vars

	ranges <- ranges[, used_vars, drop = FALSE]

	if (ncol(ranges) == 0) {
		return(NULL)
	}

	cols <- colnames(ranges)

	min <- x$min
	max <- x$max

	range_mins <- ranges["mins", ]
	range_maxs <- ranges["maxs", ]

	out <- glue::glue(
		"({cols} - {range_mins}) * ({max} - {min})/({range_maxs} - {range_mins}) + {min}"
	)

	if (is.null(x$clipping) || isTRUE(x$clipping)) {
		out <- glue::glue("pmax({out}, {min})")
		out <- glue::glue("pmin({out}, {max})")
	}

	names(out) <- cols
	out
}
