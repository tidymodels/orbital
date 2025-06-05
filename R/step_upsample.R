#' @export
orbital.step_upsample <- function(x, all_vars, ...) {
  cli::cli_abort(
    "{.fn orbital} method doesn't work for {.fn step_upsample} when \\
    {.arg skip} is {.code FALSE}."
  )
}
