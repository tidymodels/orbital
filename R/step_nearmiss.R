#' @export
orbital.step_nearmiss <- function(x, all_vars, ...) {
	cli::cli_abort(
		"{.fn orbital} method doesn't work for {.fn step_nearmiss} when \\
    {.arg skip} is {.code FALSE}."
	)
}
