#' @export
orbital.step_bin2factor <- function(x, all_vars, ...) {
  columns <- x$columns

  if (length(columns) == 0) {
    return(NULL)
  }

  out <- paste0(
    "ifelse(", columns, " == 1, \"", x$levels[1], "\", \"", x$levels[2], "\")"
  )

  names(out) <- columns
  out
}

