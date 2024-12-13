#' @export
orbital.step_smotenc <- function(x, all_vars, ...) {
	cli::cli_abort(
		"{.fn orbital} method doesn't work for {.fn step_smotenc} when \\
    {.arg skip} is {.code FALSE}."
	)
}
