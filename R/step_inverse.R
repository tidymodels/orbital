#' @export
orbital.step_inverse <- function(x, all_vars, ...) {
  offset <- x$offset

  if (offset == 0) {
    out <- paste0("1 / ", x$columns)
  } else {
    out <- paste0("1 / (", x$columns, " + ", offset, ")")
  }
  names(out) <- names(x$columns)
  out
}