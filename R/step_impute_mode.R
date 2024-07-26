#' @export
orbital.step_impute_mode <- function(x, all_vars, ...) {
  modes <- x$modes

  modes <- modes[names(modes) %in% all_vars]

  if (length(modes) == 0) {
    return(NULL)
  }

  out <- glue::glue("ifelse(is.na({names(modes)}), \"{modes}\", {names(modes)})")

  names(out) <- names(modes)
  out
}