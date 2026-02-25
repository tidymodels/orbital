#' @export
orbital.step_spline_b <- function(x, all_vars, ...) {
  spline_helper(x, all_vars, splines2::bSpline)
}
