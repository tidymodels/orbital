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
    levels <- glue::glue("\"{levels}\"")
    levels <- paste(levels, collapse = ", ")
    levels <- glue::glue("c({levels})")
    out[[col]] <- glue::glue(
      "ifelse(is.na({col}), NA, ifelse({col} %in% {levels}, {col}, \"{x$new_level}\"))"
    )
  }
  out
}