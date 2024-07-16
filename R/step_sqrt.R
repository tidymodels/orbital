#' @export
orbital.step_sqrt <- function(x, all_vars, ...) {
  out <- paste0("sqrt(", x$columns, ")")
  names(out) <- names(x$columns)
  out
}