#' @export
orbital.step_bsmote <- function(x, all_vars, ...) {
	cli::cli_abort(
		"{.fn orbital} method doesn't work for {.fn step_bsmote} when \\
    {.arg skip} is {.code FALSE}."
	)
}
