#' @export
orbital.lgb.Booster <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL
) {
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (mode == "regression") {
    res <- tidypredict::tidypredict_fit(x)
  } else if (mode == "classification") {
    objective <- x$params$objective

    if (objective %in% c("binary", "cross_entropy")) {
      res <- lightgbm_binary(x, type, lvl)
    } else if (objective %in% c("multiclass", "multiclassova")) {
      res <- lightgbm_multiclass(x, type, lvl)
    } else {
      cli::cli_abort(
        "Unsupported LightGBM objective: {.val {objective}}."
      )
    }
  }

  res
}

lightgbm_binary <- function(x, type, lvl) {
  eq <- tidypredict::tidypredict_fit(x)
  eq <- deparse1(eq)

  res <- NULL
  if ("class" %in% type) {
    levels <- glue::double_quote(lvl)

    res <- c(
      res,
      orbital_tmp_class_name = glue::glue(
        "dplyr::case_when({eq} > 0.5 ~ {levels[2]}, .default = {levels[1]})"
      )
    )
  }
  if ("prob" %in% type) {
    # eq returns P(class 1), so P(class 0) = 1 - eq
    res <- c(
      res,
      orbital_tmp_prob_name1 = glue::glue("1 - ({eq})"),
      orbital_tmp_prob_name2 = glue::glue("{eq}")
    )
  }

  res
}

lightgbm_multiclass <- function(x, type, lvl) {
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
  trees_split <- vapply(trees_split, paste, character(1), collapse = " + ")

  res <- stats::setNames(trees_split, lvl)

  if ("class" %in% type) {
    res <- c(
      res,
      orbital_tmp_class_name = softmax(lvl)
    )
  }

  if ("prob" %in% type) {
    # Compute softmax probabilities like xgboost
    eqs <- glue::glue("exp({lvl}) / norm")
    names(eqs) <- paste0("orbital_tmp_prob_name", seq_along(lvl))

    res <- c(
      res,
      "norm" = glue::glue_collapse(glue::glue("exp({lvl})"), sep = " + "),
      eqs
    )
  }

  res
}
