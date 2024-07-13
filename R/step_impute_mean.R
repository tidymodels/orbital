#' @export
orbital.step_impute_mean <- function(x, all_vars, ...) {
  means <- x$means

  if (length(means) == 0) {
    return(NULL)
  }

  out <- paste0(
    "ifelse(is.na(", names(means), "), ", means ,", ", names(means), ")"
  )
  names(out) <- names(means)
  out
}