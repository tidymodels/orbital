#' @export
orbital.step_dummy <- function(x, all_vars, ...) {
  var_in <- names(x$levels)

  out <- character()

  for (var in var_in) {
    levels <- attr(x$levels[[var]], "values")
    var_out <- x$naming(var, levels)
    level_ind <- var_out %in% all_vars
    levels <- levels[level_ind]
    var_out <- var_out[level_ind]

    eqs <- glue::glue("as.numeric({var} == \"{levels}\")")
    out <- c(out, stats::setNames(eqs, var_out))
  }

  out
}