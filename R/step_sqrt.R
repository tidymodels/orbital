#' @export
orbital.step_sqrt <- function(x, all_vars, ...) {
  columns <- x$columns

  columns <- columns[columns %in% all_vars]

  if (length(columns) == 0) {
    return(NULL)
  }

  out <- paste0("sqrt(", columns, ")")
  names(out) <- names(columns)
  out
}