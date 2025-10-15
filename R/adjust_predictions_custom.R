#' @export
orbital.predictions_custom <- function(x, ...) {
  input <- x$arguments$commands

  if (length(input) == 0) {
    return(NULL)
  }

  out <- vapply(input, rlang::as_label, character(1))
  out
}
