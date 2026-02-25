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
    "({cols} - {format_numeric(range_mins)}) * ({format_numeric(max)} - {format_numeric(min)})/({format_numeric(range_maxs)} - {format_numeric(range_mins)}) + {format_numeric(min)}"
  )

  if (is.null(x$clipping) || isTRUE(x$clipping)) {
    out <- glue::glue("pmax({out}, {format_numeric(min)})")
    out <- glue::glue("pmin({out}, {format_numeric(max)})")
  }

  names(out) <- cols
  out
}
