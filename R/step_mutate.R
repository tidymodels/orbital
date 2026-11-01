#' @export
orbital.step_mutate <- function(x, all_vars, ...) {
  input <- x$input

  input <- input[names(input) %in% all_vars]

  quos_to_eqs(input)
}

#' @exportS3Method
estimate_step_chars.step_mutate <- function(x, ...) {
  n_exprs <- length(x$inputs)
  as.integer(n_exprs * 50)
}
