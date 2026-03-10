#' @export
orbital.step_scale <- function(x, all_vars, ...) {
  sds <- x$sds

  if (length(sds) == 0) {
    return(NULL)
  }

  used_vars <- names(sds) %in% all_vars
  sds <- sds[used_vars]

  out <- glue::glue("{names(sds)} / {format_numeric(sds)}")
  names(out) <- names(sds)
  out
}

estimate_step_chars.step_scale <- function(x, ...) {
  n_cols <- length(x$sds)
  if (n_cols == 0) {
    return(0L)
  }
  avg_col_len <- mean(nchar(names(x$sds)))
  as.integer(n_cols * (10 + avg_col_len + 10))
}
