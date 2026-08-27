#' @export
orbital.ranger <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL,
  separate_trees = FALSE,
  prefix = ".pred",
  .from_parsnip = FALSE
) {
  check_bare_fit(x, .from_parsnip)
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (mode == "classification") {
    res <- ranger_classification(x, type, lvl, separate_trees, prefix)
  } else if (mode == "regression") {
    res <- ranger_regression(x, separate_trees, prefix)
  }
  res
}

ranger_regression <- function(x, separate_trees, prefix) {
  if (!separate_trees) {
    return(tidypredict::tidypredict_fit(x))
  }

  separate_trees_eqs(x, prefix)
}

ranger_classification <- function(x, type, lvl, separate_trees, prefix) {
  class_trees <- tidypredict::tidypredict_class_trees(x)
  n_trees <- tidypredict::tidypredict_n_trees(x)

  if (!separate_trees) {
    prob_sums <- sum_tree_expressions(class_trees)
    return(multiclass_from_prob_avg(prob_sums, type, lvl, n_trees))
  }

  format_classification_trees_separate(
    class_trees,
    type,
    lvl,
    prefix,
    "sum",
    n_trees
  )
}
