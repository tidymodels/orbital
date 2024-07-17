#' @export
orbital.step_mutate <- function(x, all_vars, ...) {
  input <- x$input

  out <- vapply(input, rlang::as_label, character(1))
  names(out) <- names(input)
  out
}