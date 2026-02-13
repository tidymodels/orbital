#' @export
orbital.lgb.Booster <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL
) {
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (mode == "regression") {
    res <- tidypredict::tidypredict_fit(x)
  } else if (mode == "classification") {
    objective <- x$params$objective

    if (objective %in% c("binary", "cross_entropy")) {
      res <- lightgbm_binary(x, type, lvl)
    } else {
      cli::cli_abort(
        "Multiclass classification not yet implemented for LightGBM."
      )
    }
  }

  res
}

lightgbm_binary <- function(x, type, lvl) {
  eq <- tidypredict::tidypredict_fit(x)
  eq <- deparse1(eq)

  res <- NULL
  if ("class" %in% type) {
    levels <- glue::double_quote(lvl)

    res <- c(
      res,
      orbital_tmp_class_name = glue::glue(
        "dplyr::case_when({eq} > 0.5 ~ {levels[2]}, .default = {levels[1]})"
      )
    )
  }

  res
}
