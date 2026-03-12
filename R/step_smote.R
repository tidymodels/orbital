#' @export
orbital.step_smote <- function(x, all_vars, ...) {
  cli::cli_abort(
    "{.fn orbital} method doesn't work for {.fn step_smote} when \\
    {.arg skip} is {.code FALSE}."
  )
}

#' @exportS3Method
estimate_step_chars.step_smote <- function(x, ...) {
  0L
}
