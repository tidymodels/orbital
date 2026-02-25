#' @export
orbital.ranger <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL,
  separate_trees = FALSE,
  prefix = ".pred"
) {
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

  # Extract individual trees
  trees <- tidypredict::.extract_ranger_trees(x)
  n_trees <- x$num.trees

  # Format as separate expressions
  res <- format_separate_trees(trees, prefix)

  # Apply averaging for random forest
  sum_name <- prefix
  res[[sum_name]] <- paste0(
    "(",
    res[[sum_name]],
    ") / ",
    format_numeric(n_trees)
  )

  res
}

ranger_classification <- function(x, type, lvl, separate_trees, prefix) {
  class_trees <- tidypredict::.extract_ranger_classprob(x)
  n_trees <- x$num.trees

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
