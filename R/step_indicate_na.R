#' @export
orbital.step_indicate_na <- function(x, all_vars, ...) {
  cols <- x$columns
  col_names <- glue::glue("{x$prefix}_{cols}")

  used_vars <- col_names %in% all_vars
  cols <- cols[used_vars]
  col_names <- col_names[used_vars]

  if (length(col_names) == 0) {
    return(NULL)
  }

  out <- glue::glue("as.integer(is.na({cols}))")
  
  names(out) <- col_names
  out
}