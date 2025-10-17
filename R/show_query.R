#' @importFrom dplyr show_query
#' @export
show_query.orbital_class <- function(x, con, ...) {
  x <- unclass(orbital_sql(x, con))

  if (length(x) == 0) {
    x <- paste0("[empty]")
  } else {
    x <- paste0(
      x,
      ifelse(rlang::names2(x) == "", "", paste0(" AS ", rlang::names2(x)))
    )
  }

  cat(x, sep = "\n")
}
