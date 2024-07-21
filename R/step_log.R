#' @export
orbital.step_log <- function(x, all_vars, ...) {
  columns <- x$columns

  if (length(columns) == 0) {
    return(NULL)
  }

  used_vars <- columns %in% all_vars
  columns <- columns[used_vars]

  if (x$signed) {
    out <- paste0(
      "ifelse(abs(", columns, ") < 1, 0, sign(", columns, ") * log(abs(", 
      columns, "), base = ", x$base, "))"
    )
  } else {
    out <- paste0(
      "log(", columns, " + ", x$offset, ", base = ", x$base, ")"
    )
  }

  names(out) <- columns
  out
}