#' @export
orbital.step_lencode_bayes <- function(x, all_vars, ...) {
  out <- character()

  for (i in seq_along(x$mapping)) {
    mapping <- x$mapping[[i]]
    col <- names(x$mapping)[i]

    new_ind <- mapping[["..level"]] == "..new"
    levels <- mapping[["..level"]][!new_ind]
    values <- mapping[["..value"]][!new_ind]
    default <- mapping[["..value"]][new_ind]

    eq <- paste0(col, " == \"", levels, "\" ~ ", values)
    eq <- c(eq, paste0(".default = ", default))

    eq <- paste0("dplyr::case_when(", paste0(eq, collapse = ", "), ")")
    names(eq) <- col
    out <- c(out, eq)
  }
  
  out
}