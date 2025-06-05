#' @export
orbital.step_bin2factor <- function(x, all_vars, ...) {
  columns <- x$columns
  columns <- columns[columns %in% all_vars]

  if (length(columns) == 0) {
    return(NULL)
  }

  out <- glue::glue(
    "dplyr::if_else({columns} == 1, \"{x$levels[1]}\", \"{x$levels[2]}\")"
  )

  names(out) <- columns
  out
}
