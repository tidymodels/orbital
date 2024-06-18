#' @export
orbital.model_fit <- function(x, ...) {
  res <- c(".pred" = deparse1(tidypredict::tidypredict_fit(x)))
  
  new_orbital_class(res)
}

#' @export
orbital.model_spec <- function(x, ...) {
  cli::cli_abort("{.arg x} must be fitted model.")
}
