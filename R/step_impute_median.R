#' @export
orbital.step_impute_median <- function(x, all_vars, ...) {
  medians <- x$medians

  medians <- medians[names(medians) %in% all_vars]

  if (length(medians) == 0) {
    return(NULL)
  }

  out <- glue::glue(
    "dplyr::if_else(is.na({names(medians)}), {format_numeric(medians)}, {names(medians)})"
  )

  names(out) <- names(medians)
  out
}

#' @exportS3Method
estimate_step_chars.step_impute_median <- function(x, ...) {
  n_cols <- length(x$medians)
  if (n_cols == 0) {
    return(0L)
  }
  avg_col_len <- mean(nchar(names(x$medians)))
  as.integer(n_cols * (40 + avg_col_len * 2 + 10))
}
