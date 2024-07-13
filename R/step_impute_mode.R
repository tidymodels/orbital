#' @export
orbital.step_impute_mode <- function(x, all_vars, ...) {
  modes <- x$modes

  if (length(modes) == 0) {
    return(NULL)
  }

  out <- paste0(
    "ifelse(is.na(", names(modes), "), \"", modes ,"\", ", names(modes), ")"
  )
  names(out) <- names(modes)
  out
}