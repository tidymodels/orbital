#' @export
orbital.step_YeoJohnson <- function(x, all_vars, ...) {
  lambdas <- x$lambdas
  lambdas <- lambdas[names(lambdas) %in% all_vars]

  if (length(lambdas) == 0) {
    return(NULL)
  }

  out <- vapply(
    names(lambdas),
    function(col) yeo_johnson_expr(col, lambdas[[col]]),
    character(1)
  )
  names(out) <- names(lambdas)
  out
}

yeo_johnson_expr <- function(col, lambda) {
  # Matches the default eps in recipes:::yj_transform

  eps <- 0.001

  if (abs(lambda) < eps) {
    nn_trans <- glue::glue("log({col} + 1)")
  } else {
    nn_trans <- glue::glue("(({col} + 1) ^ {lambda} - 1) / {lambda}")
  }

  if (abs(lambda - 2) < eps) {
    ng_trans <- glue::glue("-log(-{col} + 1)")
  } else {
    ng_trans <- glue::glue(
      "-((-{col} + 1) ^ {2 - lambda} - 1) / {2 - lambda}"
    )
  }

  glue::glue("dplyr::if_else({col} >= 0, {nn_trans}, {ng_trans})")
}
