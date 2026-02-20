#' @export
orbital.randomForest <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL
) {
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (mode == "classification") {
    class_trees <- tidypredict::.extract_rf_classprob(x, nested = TRUE)
    n_trees <- x$ntree
    vote_sums <- sum_tree_expressions(class_trees)
    res <- multiclass_from_votes(vote_sums, type, lvl, n_trees)
  } else if (mode == "regression") {
    res <- tidypredict::tidypredict_fit(x, nested = TRUE)
  }
  res
}
