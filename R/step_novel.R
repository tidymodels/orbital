#' @export
orbital.step_novel <- function(x, all_vars, ...) {
  objects <- x$objects

  objects <- objects[names(objects) %in% all_vars]

  if (length(objects) == 0) {
    return(NULL)
  }

  out <- character()
  for (col in names(objects)) { 
    levels <- objects[[col]]
    levels <- paste0("\"", levels, "\"")
    levels <- paste0(levels, collapse = ", ")
    levels <- paste0("c(", levels, ")")
    out[[col]] <- paste0(
      "ifelse(is.na(", col, "), NA, ifelse(", col, " %in% ", levels, ", ", col,
      ", \"", x$new_level,"\"))"
    )
  }
  out
}