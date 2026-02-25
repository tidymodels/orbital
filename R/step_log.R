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
