#' @export
orbital.step_impute_mean <- function(x, all_vars, ...) {
  means <- x$means

  means <- means[names(means) %in% all_vars]

  if (length(means) == 0) {
    return(NULL)
  }

  out <- glue::glue(
    "dplyr::if_else(is.na({names(means)}), {means}, {names(means)})"
  )

  names(out) <- names(means)
  out
}
