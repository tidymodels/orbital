#' @export
orbital.step_normalize <- function(x, all_vars, ...) {
  means <- x$means
  sds <- x$sds

  if (length(means) == 0) {
    return(NULL)
  }

  used_vars <- names(means) %in% all_vars
  means <- means[used_vars]
  sds <- sds[used_vars]

  out <- glue::glue(
    "({names(means)} - {format_numeric(means)}) / {format_numeric(sds)}"
  )

  names(out) <- names(means)
  out
}
