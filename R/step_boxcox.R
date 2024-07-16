#' @export
orbital.step_BoxCox <- function(x, all_vars, ...) {
  lambdas <- x$lambdas

  if (length(lambdas) == 0) {
    return(NULL)
  }

  out <- ifelse(
    abs(lambdas) < 0.001,
    paste0("log(", names(lambdas), ")"),
    paste0("(", names(lambdas), " ^ ", lambdas, " - 1) / ", lambdas)
  )
  out
}