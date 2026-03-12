#' @export
orbital.step_rose <- function(x, all_vars, ...) {
  cli::cli_abort(
    "{.fn orbital} method doesn't work for {.fn step_rose} when \\
    {.arg skip} is {.code FALSE}."
  )
}

#' @exportS3Method
estimate_step_chars.step_rose <- function(x, ...) {
  0L
}
