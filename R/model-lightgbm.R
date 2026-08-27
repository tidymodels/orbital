#' @export
orbital.lgb.Booster <- function(
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

  separate_trees_eqs(x, prefix)
}

lightgbm_binary <- function(x, type, lvl, separate_trees, prefix) {
  if (!separate_trees) {
    eq <- tidypredict::tidypredict_fit(x)
    eq <- deparse1(eq, control = "digits17")
    return(binary_from_prob(eq, type, lvl))
  }

  # `tidypredict_combine_trees()` applies the objective's inverse link, so the
  # combined column holds a probability rather than a logit.
  prob_prefix <- paste0(prefix, "_prob")
  res <- separate_trees_eqs(x, prob_prefix)

  binary_from_prob_with_eq(res, backtick(prob_prefix), type, lvl)
}

lightgbm_multiclass <- function(x, type, lvl, separate_trees, prefix) {
  # Follow xgboost pattern: extract trees and sum by class
  trees <- tidypredict::tidypredict_trees(x)

  num_class <- length(lvl)

  # Trees are emitted round-major, so position determines class. The extractor
  # includes single-leaf trees, so no position is ever missing and the class
  # assignment does not need to be recovered from the model's JSON dump.
  class_assignments <- (seq_along(trees) - 1L) %% num_class + 1L
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
