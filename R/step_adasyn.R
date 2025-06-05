#' @export
orbital.step_adasyn <- function(x, all_vars, ...) {
  cli::cli_abort(
    "{.fn orbital} method doesn't work for {.fn step_adasyn} when \\
    {.arg skip} is {.code FALSE}."
  )
}
