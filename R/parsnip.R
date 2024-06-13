#' @export
weasel.model_fit <- function(x, ...) {
  res <- c(".pred" = deparse1(tidypredict::tidypredict_fit(x)))
  
  new_weasel_class(res)
}

#' @export
weasel.model_spec <- function(x, ...) {
  cli::cli_abort("{.arg x} must be fitted model.")
}
