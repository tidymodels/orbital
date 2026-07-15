#' @export
orbital.step_pca <- function(x, all_vars, ...) {
  rot <- x$res$rotation
  out <- pca_helper(rot, x$prefix, all_vars)
  out
}

#' @exportS3Method
estimate_step_chars.step_pca <- function(x, ...) {
  rot <- x$res$rotation
  n_components <- ncol(rot)
  n_vars <- nrow(rot)
  avg_var_len <- mean(nchar(rownames(rot)))
  chars_per_component <- n_vars * (15 + avg_var_len)
  as.integer(n_components * chars_per_component)
}
