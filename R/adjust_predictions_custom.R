#' @export
orbital.predictions_custom <- function(x, ...) {
  input <- x$arguments$commands

  if (length(input) == 0) {
    return(NULL)
  }

  quos_to_eqs(input)
}

# Estimate based on number of expressions, ~50 chars each
#' @exportS3Method
estimate_adj_chars.predictions_custom <- function(x, ...) {
  n_exprs <- length(x$arguments$commands)
  if (n_exprs == 0) {
    return(0L)
  }
  as.integer(n_exprs * 50)
}
