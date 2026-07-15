#' @export
orbital.step_impute_mean <- function(x, all_vars, ...) {
  means <- x$means

  means <- means[names(means) %in% all_vars]

  if (length(means) == 0) {
    return(NULL)
  }

  out <- glue::glue(
    "dplyr::if_else(is.na({names(means)}), {format_numeric(means)}, {names(means)})"
  )

  names(out) <- names(means)
  out
}

#' @exportS3Method
estimate_step_chars.step_impute_mean <- function(x, ...) {
  n_cols <- length(x$means)
  if (n_cols == 0) {
    return(0L)
  }
  avg_col_len <- mean(nchar(names(x$means)))
  as.integer(n_cols * (40 + avg_col_len * 2 + 10))
}
