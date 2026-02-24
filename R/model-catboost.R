#' @export
orbital.catboost.Model <- function(
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
    res <- catboost_regression(x, separate_trees, prefix)
  } else if (mode == "classification") {
    pm <- tidypredict::parse_model(x)
    objective <- pm$general$params$objective %||% "Logloss"

    if (objective %in% c("Logloss", "CrossEntropy")) {
      res <- catboost_binary(x, type, lvl, separate_trees, prefix)
    } else if (objective %in% c("MultiClass", "MultiClassOneVsAll")) {
      res <- catboost_multiclass(x, type, lvl, separate_trees, prefix)
    } else {
      cli::cli_abort(
        "Unsupported CatBoost objective: {.val {objective}}."
      )
    }
  }

  res
}

catboost_regression <- function(x, separate_trees, prefix) {
  if (!separate_trees) {
    return(tidypredict::tidypredict_fit(x))
  }

  # Extract individual trees
  trees <- tidypredict::.extract_catboost_trees(x)

  # Format as separate expressions
  res <- format_separate_trees(trees, prefix)

  # Apply scale and bias from parsed model
  pm <- tidypredict::parse_model(x)
  scale <- pm$general$scale %||% 1
  bias <- pm$general$bias %||% 0

  sum_name <- prefix
  if (scale != 1) {
    res[[sum_name]] <- paste0(scale, " * (", res[[sum_name]], ")")
  }
  if (bias != 0) {
    res[[sum_name]] <- paste0(res[[sum_name]], " + ", bias)
  }

  res
}

catboost_multiclass <- function(x, type, lvl, separate_trees, prefix) {
  trees <- tidypredict::.extract_catboost_trees(x)

  num_class <- length(lvl)

  # Group trees by class: tree i belongs to class (i %% num_class)
  tree_indices <- seq_along(trees) - 1L
  class_assignments <- (tree_indices %% num_class) + 1L
  trees_split <- split(trees, class_assignments)

  # Collapse stumps and sum trees for each class
  trees_split <- lapply(trees_split, collapse_stumps)

  if (!separate_trees) {
    trees_split <- vapply(trees_split, paste, character(1), collapse = " + ")
    return(multiclass_from_logits(trees_split, type, lvl))
  }

  format_multiclass_logits_separate(trees_split, type, lvl, prefix)
}

catboost_binary <- function(x, type, lvl, separate_trees, prefix) {
  if (!separate_trees) {
    eq <- tidypredict::tidypredict_fit(x)
    eq <- deparse1(eq)
    return(binary_from_prob(eq, type, lvl))
  }

  # separate_trees = TRUE
  trees <- tidypredict::.extract_catboost_trees(x)

  # Format trees separately, using a logit prefix
  logit_prefix <- paste0(prefix, "_logit")
  res <- format_separate_trees(trees, logit_prefix)

  # Apply logistic transformation to the sum
  logit_name <- backtick(logit_prefix)
  prob_eq <- paste0("1/(1 + exp(-", logit_name, "))")

  res <- binary_from_prob_with_eq(res, prob_eq, type, lvl)
  res
}
