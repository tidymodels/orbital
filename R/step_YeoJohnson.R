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
  lambda_fmt <- format_numeric(lambda)
  lambda_2_fmt <- format_numeric(2 - lambda)

  if (abs(lambda) < eps) {
    nn_trans <- glue::glue("log({col} + 1)")
  } else {
    nn_trans <- glue::glue("(({col} + 1) ^ {lambda_fmt} - 1) / {lambda_fmt}")
  }

  if (abs(lambda - 2) < eps) {
    ng_trans <- glue::glue("-log(-{col} + 1)")
  } else {
    ng_trans <- glue::glue(
      "-((-{col} + 1) ^ {lambda_2_fmt} - 1) / {lambda_2_fmt}"
    )
  }

  glue::glue("dplyr::if_else({col} >= 0, {nn_trans}, {ng_trans})")
}
