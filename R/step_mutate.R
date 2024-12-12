#' @export
orbital.step_mutate <- function(x, all_vars, ...) {
	input <- x$input

	input <- input[names(input) %in% all_vars]

	out <- vapply(input, rlang::as_label, character(1))
	names(out) <- names(input)
	out
}
