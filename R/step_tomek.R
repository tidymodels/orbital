#' @export
orbital.step_tomek <- function(x, all_vars, ...) {
	cli::cli_abort(
		"{.fn orbital} method doesn't work for {.fn step_tomek} when \\
    {.arg skip} is {.code FALSE}."
	)
}
