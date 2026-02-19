#' @export
orbital.earth <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL
) {
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (mode == "classification") {
    n_classes <- length(lvl)
    if (n_classes > 2) {
      cli::cli_abort(
        "Multiclass earth models are not yet supported."
      )
    }
    # Binary classification - tidypredict_fit returns P(second level)
    eq <- tidypredict::tidypredict_fit(x)
    eq <- deparse1(eq)

    res <- binary_from_prob(eq, type, lvl)
  } else if (mode == "regression") {
    res <- tidypredict::tidypredict_fit(x)
  }
  res
}
