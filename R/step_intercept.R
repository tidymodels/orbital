#' @export
orbital.step_intercept <- function(x, all_vars, ...) {
  name <- x$name
  value <- x$value

  if (!name %in% all_vars) {
    return(NULL)
  }

  out <- as.character(value)
  names(out) <- name
  out
}
