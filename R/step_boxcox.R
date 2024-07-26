#' @export
orbital.step_BoxCox <- function(x, all_vars, ...) {
  lambdas <- x$lambdas
  lambdas <- lambdas[names(lambdas) %in% all_vars]

  if (length(lambdas) == 0) {
    return(NULL)
  }

  out <- ifelse(
    abs(lambdas) < 0.001,
    glue::glue("log({names(lambdas)})"),
    glue::glue("({names(lambdas)} ^ {lambdas} - 1) / {lambdas}")
  )
  out
}