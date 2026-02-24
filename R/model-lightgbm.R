#' @export
orbital.lgb.Booster <- function(
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

  if (mode == "regression") {
    res <- lightgbm_regression(x, separate_trees, prefix)
  } else if (mode == "classification") {
    objective <- x$params$objective

    if (objective %in% c("binary", "cross_entropy")) {
      res <- lightgbm_binary(x, type, lvl, separate_trees, prefix)
    } else if (objective %in% c("multiclass", "multiclassova")) {
      res <- lightgbm_multiclass(x, type, lvl, separate_trees, prefix)
    } else {
      cli::cli_abort(
        "Unsupported LightGBM objective: {.val {objective}}."
      )
    }
  }

  res
}

lightgbm_regression <- function(x, separate_trees, prefix) {
  if (!separate_trees) {
    return(tidypredict::tidypredict_fit(x))
  }

  # Extract individual trees
  trees <- tidypredict::.extract_lgb_trees(x)

  # Format as separate expressions
  format_separate_trees(trees, prefix)
}

lightgbm_binary <- function(x, type, lvl, separate_trees, prefix) {
  if (!separate_trees) {
    eq <- tidypredict::tidypredict_fit(x)
    eq <- deparse1(eq)
    return(binary_from_prob(eq, type, lvl))
  }

  # separate_trees = TRUE
  trees <- tidypredict::.extract_lgb_trees(x)

  # Format trees separately, using a logit prefix
  logit_prefix <- paste0(prefix, "_logit")
  res <- format_separate_trees(trees, logit_prefix)

  # Apply logistic transformation to the sum
  logit_name <- backtick(logit_prefix)
  prob_eq <- paste0("1/(1 + exp(-", logit_name, "))")

  res <- binary_from_prob_with_eq(res, prob_eq, type, lvl)
  res
}

lightgbm_multiclass <- function(x, type, lvl, separate_trees, prefix) {
  # Follow xgboost pattern: extract trees and sum by class
  trees <- tidypredict::.extract_lgb_trees(x)

  pm <- tidypredict::parse_model(x)
  num_class <- length(lvl)
  niter <- pm$general$niter
  total_trees <- niter * num_class

  # tidypredict skips empty trees (num_leaves == 1), so we need to identify
  # which tree indices were kept to correctly assign classes
  n_extracted <- length(trees)

  if (n_extracted == total_trees) {
    # No empty trees, simple case like xgboost
    tree_indices <- seq_len(total_trees) - 1L
  } else {
    # Some trees were skipped - get indices of non-empty trees from JSON dump
    model_json <- x$dump_model()
    model_info <- jsonlite::fromJSON(model_json)
    non_empty <- model_info$tree_info$num_leaves > 1
    tree_indices <- model_info$tree_info$tree_index[non_empty]
  }

  # Group trees by class: tree i belongs to class (i %% num_class)
  class_assignments <- (tree_indices %% num_class) + 1
  trees_split <- split(trees, class_assignments)

  # Collapse stumps and sum trees for each class (like xgboost)
  trees_split <- lapply(trees_split, collapse_stumps)

  if (!separate_trees) {
    trees_split <- vapply(
      trees_split,
      function(trees) {
        tree_strs <- vapply(
          trees,
          function(e) deparse1(e, control = "digits17"),
          character(1)
        )
        paste(tree_strs, collapse = " + ")
      },
      character(1)
    )
    return(multiclass_from_logits(trees_split, type, lvl))
  }

  format_multiclass_logits_separate(trees_split, type, lvl, prefix)
}
