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

#' @exportS3Method
estimate_step_chars.step_center <- function(x, ...) {
  n_cols <- length(x$means)
  if (n_cols == 0) {
    return(0L)
  }
  avg_col_len <- mean(nchar(names(x$means)))
  as.integer(n_cols * (15 + avg_col_len + 10))
}
