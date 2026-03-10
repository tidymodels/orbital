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

estimate_step_chars.step_normalize <- function(x, ...) {
  n_cols <- length(x$means)
  if (n_cols == 0) {
    return(0L)
  }
  avg_col_len <- mean(nchar(names(x$means)))
  as.integer(n_cols * (30 + avg_col_len + 20))
}
