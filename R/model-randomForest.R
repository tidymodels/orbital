#' @export
orbital.randomForest <- function(
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
    res <- rf_classification(x, type, lvl, separate_trees, prefix)
  } else if (mode == "regression") {
    res <- rf_regression(x, separate_trees, prefix)
  }
  res
}

rf_regression <- function(x, separate_trees, prefix) {
  if (!separate_trees) {
    return(tidypredict::tidypredict_fit(x))
  }

  # Extract individual trees
  trees <- tidypredict::.extract_rf_trees(x)
  n_trees <- x$ntree

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

rf_classification <- function(x, type, lvl, separate_trees, prefix) {
  class_trees <- tidypredict::.extract_rf_classprob(x)
  n_trees <- x$ntree

  if (!separate_trees) {
    vote_sums <- sum_tree_expressions(class_trees)
    return(multiclass_from_votes(vote_sums, type, lvl, n_trees))
  }

  format_classification_trees_separate(
    class_trees,
    type,
    lvl,
    prefix,
    "votes",
    n_trees
  )
}
