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
      # Multiclass classification
      class_eqs <- tidypredict::.extract_earth_multiclass(x)
      # Reorder to match lvl order
      class_eqs <- class_eqs[lvl]
      res <- multiclass_from_logits(unlist(class_eqs), type, lvl)
    } else {
      # Binary classification - tidypredict_fit returns P(second level)
      eq <- tidypredict::tidypredict_fit(x)
      eq <- deparse1(eq)

      res <- binary_from_prob(eq, type, lvl)
    }
  } else if (mode == "regression") {
    res <- tidypredict::tidypredict_fit(x)
  }
  res
}
