#' @export
orbital.step_nearmiss <- function(x, all_vars, ...) {
  cli::cli_abort(
    "{.fn orbital} method doesn't work for {.fn step_nearmiss} when \\
    {.arg skip} is {.code FALSE}."
  )
}

#' @exportS3Method
estimate_step_chars.step_nearmiss <- function(x, ...) {
  0L
}
