#' @export
orbital.xgb.Booster <- function(
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
    objective <- x$params$objective %||%
      attr(x, "params")$objective %||%
      attr(x, "param")$objective

    # Infer objective from number of classes if not found
    if (is.null(objective)) {
      num_class <- x$params$num_class %||%
        attr(x, "params")$num_class %||%
        attr(x, "param")$num_class
      objective <- if (!is.null(num_class) && num_class > 2) {
        "multi:softprob"
      } else {
        "binary:logistic"
      }
    }

    objective <- rlang::arg_match0(
      objective,
      c("multi:softprob", "binary:logistic")
    )

    extractor <- switch(
      objective,
      "multi:softprob" = xgboost_multisoft,
      "binary:logistic" = xgboost_logistic
    )

    res <- extractor(x, type, lvl, separate_trees, prefix)
  } else if (mode == "regression") {
    res <- xgboost_regression(x, separate_trees, prefix)
  }
  res
}

xgboost_regression <- function(x, separate_trees, prefix) {
  if (!separate_trees) {
    return(tidypredict::tidypredict_fit(x))
  }

  separate_trees_eqs(x, prefix)
}

xgboost_multisoft <- function(x, type, lvl, separate_trees, prefix) {
  trees <- tidypredict::tidypredict_trees(x)

  # Trees are emitted round-major: one per class, then the next round.
  trees_split <- split(
    trees,
    rep(seq_along(lvl), length.out = length(trees))
  )
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

xgboost_logistic <- function(x, type, lvl, separate_trees, prefix) {
  if (!separate_trees) {
    eq <- tidypredict::tidypredict_fit(x)
    eq <- deparse1(eq, control = "digits17")
    return(binary_from_prob_first(eq, type, lvl))
  }

  # `tidypredict_combine_trees()` applies the objective's inverse link, so the
  # combined column holds the same probability `tidypredict_fit()` returns, and
  # is oriented the same way: `P(first level)`, as the collapsed path assumes.
  prob_prefix <- paste0(prefix, "_prob")
  res <- separate_trees_eqs(x, prob_prefix)

  binary_from_prob_first_with_eq(res, backtick(prob_prefix), type, lvl)
}
