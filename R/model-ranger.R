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
  res[[sum_name]] <- paste0("(", res[[sum_name]], ") / ", n_trees)

  res
}

ranger_classification <- function(x, type, lvl, separate_trees, prefix) {
  class_trees <- tidypredict::.extract_ranger_classprob(x)
  n_trees <- x$num.trees

  if (!separate_trees) {
    prob_sums <- sum_tree_expressions(class_trees)
    return(multiclass_from_prob_avg(prob_sums, type, lvl, n_trees))
  }

  # separate_trees = TRUE: format each class's trees separately
  res <- character()
  for (cls in names(class_trees)) {
    cls_trees <- class_trees[[cls]]
    cls_prefix <- paste0(prefix, "_", cls, "_sum")
    cls_res <- format_separate_trees(cls_trees, cls_prefix)
    res <- c(res, cls_res)
  }

  # Add probability calculations (divide by n_trees) and class selection
  lvl_sum_names <- paste0(prefix, "_", lvl, "_sum")
  lvl_bt <- backtick(lvl_sum_names)

  if ("prob" %in% type) {
    prob_eqs <- paste0("(", lvl_bt, ") / ", n_trees)
    names(prob_eqs) <- paste0("orbital_tmp_prob_name", seq_along(lvl))
    res <- c(res, prob_eqs)
  }
  if ("class" %in% type) {
    res <- c(
      res,
      orbital_tmp_class_name = softmax_class_from_names(lvl_sum_names, lvl)
    )
  }

  res
}
