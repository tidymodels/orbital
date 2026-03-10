#' @export
orbital.step_log <- function(x, all_vars, ...) {
  columns <- x$columns

  if (length(columns) == 0) {
    return(NULL)
  }

  used_vars <- columns %in% all_vars
  columns <- columns[used_vars]

  if (x$signed) {
    out <- glue::glue(
      "dplyr::if_else(abs({columns}) < 1, 0, sign({columns}) * log(abs({columns}), base = {format_numeric(x$base)}))"
    )
  } else {
    out <- glue::glue(
      "log({columns} + {format_numeric(x$offset)}, base = {format_numeric(x$base)})"
    )
  }

  names(out) <- columns
  out
}

estimate_step_chars.step_log <- function(x, ...) {
  n_cols <- length(x$columns)
  if (n_cols == 0) {
    return(0L)
  }
  base_chars <- if (x$signed) 80 else 30
  avg_col_len <- mean(nchar(x$columns))
  as.integer(n_cols * (base_chars + avg_col_len))
}
