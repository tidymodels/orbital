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

  out <- paste0(
    "(", cols, " - ", ranges["mins", ], ") * (", max, " - ", min, ")/(", 
    ranges["maxs", ], " - ", ranges["mins", ], ") + ", min
  )

  if (is.null(x$clipping) || isTRUE(x$clipping)) {
    out <- paste0("pmax(", out, ", ", min, ")")
    out <- paste0("pmin(", out, ", ", max, ")")
  }
  
  names(out) <- cols
  out
}