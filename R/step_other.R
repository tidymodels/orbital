#' @export
orbital.step_other <- function(x, all_vars, ...) {
  objects <- x$objects

  if (length(objects) == 0) {
    return(NULL)
  }

  out <- character()
  for (col in names(objects)) { 
    if (!objects[[col]]$collapse) {
      next
    }
    levels <- objects[[col]]$keep
    levels <- paste0("\"", levels, "\"")
    levels <- paste0(levels, collapse = ", ")
    levels <- paste0("c(", levels, ")")
    out[[col]] <- paste0(
      "ifelse(is.na(", col, "), NA, ifelse(", col, " %in% ", levels, ", ", col,
      ", \"", objects[[col]]$other, "\"))"
    )
  }
  out
}