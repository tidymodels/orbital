#' @export
orbital.step_pca_sparse <- function(x, all_vars, ...) {
  rot <- x$res
  out <- pca_helper(rot, x$prefix, all_vars)
  out
}
