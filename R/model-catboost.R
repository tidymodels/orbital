#' @export
orbital.catboost.Model <- function(
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
    res <- NULL
  }

  res
}
