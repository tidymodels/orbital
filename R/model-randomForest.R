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
  res[[sum_name]] <- paste0("(", res[[sum_name]], ") / ", n_trees)

  res
}

rf_classification <- function(x, type, lvl, separate_trees, prefix) {
  class_trees <- tidypredict::.extract_rf_classprob(x)
  n_trees <- x$ntree

  if (!separate_trees) {
    vote_sums <- sum_tree_expressions(class_trees)
    return(multiclass_from_votes(vote_sums, type, lvl, n_trees))
  }

  # separate_trees = TRUE: format each class's trees separately
  res <- character()
  for (cls in names(class_trees)) {
    cls_trees <- class_trees[[cls]]
    cls_prefix <- paste0(prefix, "_", cls, "_votes")
    cls_res <- format_separate_trees(cls_trees, cls_prefix)
    res <- c(res, cls_res)
  }

  # Add probability calculations (divide by n_trees) and class selection
  lvl_votes_names <- paste0(prefix, "_", lvl, "_votes")
  lvl_bt <- backtick(lvl_votes_names)

  if ("prob" %in% type) {
    prob_eqs <- paste0("(", lvl_bt, ") / ", n_trees)
    names(prob_eqs) <- paste0("orbital_tmp_prob_name", seq_along(lvl))
    res <- c(res, prob_eqs)
  }
  if ("class" %in% type) {
    res <- c(
      res,
      orbital_tmp_class_name = softmax_class_from_names(lvl_votes_names, lvl)
    )
  }

  res
}
