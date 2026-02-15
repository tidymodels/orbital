#' @export
orbital.catboost.Model <- function(
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

  res <- stats::setNames(trees_split, lvl)

  if ("class" %in% type) {
    res <- c(
      res,
      orbital_tmp_class_name = softmax(lvl)
    )
  }

  if ("prob" %in% type) {
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

catboost_binary <- function(x, type, lvl) {
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
