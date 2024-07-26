#' @export
orbital.step_other <- function(x, all_vars, ...) {
  objects <- x$objects

  objects <- objects[names(objects) %in% all_vars]

  if (length(objects) == 0) {
    return(NULL)
  }

  out <- character()
  for (col in names(objects)) { 
    if (!objects[[col]]$collapse) {
      next
    }
    levels <- objects[[col]]$keep
    levels <- glue::glue("\"{levels}\"")
    levels <- paste(levels, collapse = ", ")
    levels <- glue::glue("c({levels})")
    out[[col]] <- glue::glue(
      "ifelse(is.na({col}), NA, ifelse({col} %in% {levels}, {col}, \"{objects[[col]]$other}\"))"
    )
  }
  out
}