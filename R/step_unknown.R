#' @export
orbital.step_unknown <- function(x, all_vars, ...) {
  vars <- names(x$objects)

  vars <- vars[vars %in% all_vars]

  if (length(vars) == 0) {
    return(NULL)
  }

  out <- paste0(
    "ifelse(is.na(", vars, "), \"", x$new_level ,"\", ", vars, ")"
  )
  names(out) <- vars
  out
}