#' @export
orbital.step_center <- function(x, all_vars, ...) {
  means <- x$means

  if (length(means) == 0) {
    return(NULL)
  }

  used_vars <- names(means) %in% all_vars
  means <- means[used_vars]

  out <- glue::glue("{names(means)} - {format_numeric(means)}")
  names(out) <- names(means)
  out
}
