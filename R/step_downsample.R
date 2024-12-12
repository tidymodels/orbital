#' @export
orbital.step_downsample <- function(x, all_vars, ...) {
	cli::cli_abort(
		"{.fn orbital} method doesn't work for {.fn step_downsample} when \\
    {.arg skip} is {.code FALSE}."
	)
}
