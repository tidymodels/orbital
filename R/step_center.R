#' @export
orbital.step_center <- function(x, all_vars, ...) {
  means <- x$means

  used_vars <- names(means) %in% all_vars
  means <- means[used_vars]

  out <- paste0(names(means), " - ", means)
  names(out) <- names(means)
  out
}