#' @export
orbital.step_impute_median <- function(x, all_vars, ...) {
  medians <- x$medians

  medians <- medians[names(medians) %in% all_vars]

  if (length(medians) == 0) {
    return(NULL)
  }

  out <- glue::glue(
    "dplyr::if_else(is.na({names(medians)}), {medians}, {names(medians)})"
  )

  names(out) <- names(medians)
  out
}
