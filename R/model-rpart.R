#' @export
orbital.rpart <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL
) {
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (mode == "classification") {
    res <- character()
    if ("class" %in% type) {
      eq <- tidypredict::tidypredict_fit(x)
      eq <- deparse1(eq)
      res <- c(res, orbital_tmp_class_name = eq)
    }
    if ("prob" %in% type) {
      eqs <- tidypredict::.extract_rpart_classprob(x)
      names(eqs) <- paste0("orbital_tmp_prob_name", seq_along(lvl))
      res <- c(res, eqs)
    }
  } else if (mode == "regression") {
    res <- tidypredict::tidypredict_fit(x)
  }
  res
}
