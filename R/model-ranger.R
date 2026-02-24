#' @export
orbital.ranger <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL,
  separate_trees = FALSE
) {
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (mode == "classification") {
    class_trees <- tidypredict::.extract_ranger_classprob(x)
    n_trees <- x$num.trees
    prob_sums <- sum_tree_expressions(class_trees)
    res <- multiclass_from_prob_avg(prob_sums, type, lvl, n_trees)
  } else if (mode == "regression") {
    res <- tidypredict::tidypredict_fit(x)
  }
  res
}
