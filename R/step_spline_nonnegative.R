#' @export
orbital.step_spline_nonnegative <- function(x, all_vars, ...) {
  spline_helper(x, all_vars, splines2::mSpline)
}
