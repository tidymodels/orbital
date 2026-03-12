#' @export
orbital.step_sqrt <- function(x, all_vars, ...) {
  columns <- x$columns

  columns <- columns[columns %in% all_vars]

  if (length(columns) == 0) {
    return(NULL)
  }

  out <- glue::glue("sqrt({columns})")

  names(out) <- names(columns)
  out
}

#' @exportS3Method
estimate_step_chars.step_sqrt <- function(x, ...) {
  n_cols <- length(x$columns)
  if (n_cols == 0) {
    return(0L)
  }
  avg_col_len <- mean(nchar(x$columns))
  as.integer(n_cols * (10 + avg_col_len))
}
