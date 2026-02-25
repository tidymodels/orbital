#' @export
orbital.step_spline_convex <- function(x, all_vars, ...) {
  spline_helper(x, all_vars, splines2::cSpline)
}
