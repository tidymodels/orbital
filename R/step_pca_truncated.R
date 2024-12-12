#' @export
orbital.step_pca_truncated <- function(x, all_vars, ...) {
	rot <- x$res$rotation
	out <- pca_helper(rot, x$prefix, all_vars)
	out
}
