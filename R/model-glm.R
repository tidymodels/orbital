#' @export
orbital.glm <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL
) {
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (mode == "classification") {
    if (is.null(lvl)) {
      outcome <- names(attr(x$terms, "dataClasses"))[attr(x$terms, "response")]
      lvl <- levels(x$data[[outcome]])
    }

    eq <- tidypredict::tidypredict_fit(x)
    eq <- deparse1(eq, control = "digits17")

    res <- binary_from_prob(eq, type, lvl)
  } else if (mode == "regression") {
    res <- tidypredict::tidypredict_fit(x)
  }
  res
}
