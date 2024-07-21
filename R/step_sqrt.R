#' @export
orbital.step_sqrt <- function(x, all_vars, ...) {
  columns <- x$columns

  if (length(columns) == 0) {
    return(NULL)
  }

  out <- paste0("sqrt(", columns, ")")
  names(out) <- names(columns)
  out
}