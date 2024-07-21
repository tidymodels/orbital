#' @export
orbital.step_scale <- function(x, all_vars, ...) {
  sds <- x$sds

  if (length(sds) == 0) {
    return(NULL)
  }

  used_vars <- names(sds) %in% all_vars
  sds <- sds[used_vars]

  out <- paste0(names(sds) ," / ", sds)
  names(out) <- names(sds)
  out
}