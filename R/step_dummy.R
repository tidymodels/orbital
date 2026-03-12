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

    eqs <- glue::glue("dplyr::if_else({var} == \"{levels}\", 1, 0)")
    out <- c(out, stats::setNames(eqs, var_out))
  }

  out
}

#' @exportS3Method
estimate_step_chars.step_dummy <- function(x, ...) {
  total <- 0L
  for (var in names(x$levels)) {
    levels <- attr(x$levels[[var]], "values")
    n_levels <- length(levels)
    avg_level_len <- if (n_levels > 0) mean(nchar(levels)) else 5
    total <- total + as.integer(n_levels * (25 + nchar(var) + avg_level_len))
  }
  total
}
