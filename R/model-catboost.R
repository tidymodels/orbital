#' @export
orbital.catboost.Model <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL,
  separate_trees = FALSE
) {
  mode <- rlang::arg_match(mode)

  type <- default_type(type)

  if (mode == "regression") {
    res <- tidypredict::tidypredict_fit(x)
  } else if (mode == "classification") {
    pm <- tidypredict::parse_model(x)
    objective <- pm$general$params$objective %||% "Logloss"

    if (objective %in% c("Logloss", "CrossEntropy")) {
      res <- catboost_binary(x, type, lvl)
    } else if (objective %in% c("MultiClass", "MultiClassOneVsAll")) {
      res <- catboost_multiclass(x, type, lvl)
    } else {
      cli::cli_abort(
        "Unsupported CatBoost objective: {.val {objective}}."
      )
    }
  }

  res
}

catboost_multiclass <- function(x, type, lvl) {
  trees <- tidypredict::.extract_catboost_trees(x)

  num_class <- length(lvl)

  # Group trees by class: tree i belongs to class (i %% num_class)
  tree_indices <- seq_along(trees) - 1L
  class_assignments <- (tree_indices %% num_class) + 1L
  trees_split <- split(trees, class_assignments)

  # Collapse stumps and sum trees for each class
  trees_split <- lapply(trees_split, collapse_stumps)
  trees_split <- vapply(trees_split, paste, character(1), collapse = " + ")

  multiclass_from_logits(trees_split, type, lvl)
}

catboost_binary <- function(x, type, lvl) {
  eq <- tidypredict::tidypredict_fit(x)
  eq <- deparse1(eq)

  binary_from_prob(eq, type, lvl)
}
