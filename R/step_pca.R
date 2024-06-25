#' @export
orbital.step_pca <- function(x, all_vars, ...) {
  rot <- x$res$rotation
  colnames(rot) <- recipes::names0(ncol(rot), x$prefix)

  used_vars <- colnames(rot) %in% all_vars

  rot <- rot[, used_vars]

  row_nms <- rownames(rot)

  out <- character(length(all_vars))
  for (i in seq_along(all_vars)) {
    out[i] <- paste(row_nms, "*", rot[, i], collapse = " + ")
  }

  names(out) <- all_vars
  out
}