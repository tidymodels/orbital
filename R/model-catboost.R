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

  separate_trees_eqs(x, prefix)
}

catboost_multiclass <- function(x, type, lvl, separate_trees, prefix) {
  trees <- tidypredict::tidypredict_trees(x)

  num_class <- length(lvl)

  # Group trees by class: tree i belongs to class (i %% num_class)
  tree_indices <- seq_along(trees) - 1L
  class_assignments <- (tree_indices %% num_class) + 1L
  trees_split <- split(trees, class_assignments)

  # Collapse stumps and sum trees for each class
  trees_split <- lapply(trees_split, collapse_stumps)

  if (!separate_trees) {
    trees_split <- vapply(
      trees_split,
      function(trees) {
        tree_strs <- vapply(
          trees,
          deparse_exact,
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

catboost_binary <- function(x, type, lvl, separate_trees, prefix) {
  if (!separate_trees) {
    eq <- tidypredict::tidypredict_fit(x)
    eq <- deparse_exact(eq)
    return(binary_from_prob(eq, type, lvl))
  }

  # `tidypredict_combine_trees()` applies the scale, bias and inverse link, so
  # the combined column holds a probability rather than a logit. The old code
  # here applied neither scale nor bias, unlike the regression path.
  prob_prefix <- paste0(prefix, "_prob")
  res <- separate_trees_eqs(x, prob_prefix)

  binary_from_prob_with_eq(res, backtick(prob_prefix), type, lvl)
}
