#' @export
orbital.xgb.Booster <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL,
  separate_trees = FALSE
) {
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (mode == "classification") {
    objective <- x$params$objective %||% attr(x, "params")$objective
    objective <- rlang::arg_match0(
      objective,
      c("multi:softprob", "binary:logistic")
    )

    extractor <- switch(
      objective,
      "multi:softprob" = xgboost_multisoft,
      "binary:logistic" = xgboost_logistic
    )

    res <- extractor(x, type, lvl)
  } else if (mode == "regression") {
    res <- tidypredict::tidypredict_fit(x)
  }
  res
}

xgboost_multisoft <- function(x, type, lvl) {
  trees <- tidypredict::.extract_xgb_trees(x)

  trees_split <- split(
    trees,
    rep(seq_along(lvl), x$niter %||% nrow(attr(x, "evaluation_log")))
  )
  trees_split <- lapply(trees_split, collapse_stumps)
  trees_split <- vapply(trees_split, paste, character(1), collapse = " + ")

  multiclass_from_logits(trees_split, type, lvl)
}

collapse_stumps <- function(x) {
  stump_ind <- lengths(x) == 2

  stumps <- x[stump_ind]
  trees <- x[!stump_ind]

  stump_values <- lapply(stumps, function(x) eval(x[[2]][[3]]))
  stump_values <- unlist(stump_values)
  stump_values <- sum(stump_values)

  c(stump_values, trees)
}

xgboost_logistic <- function(x, type, lvl) {
  eq <- tidypredict::tidypredict_fit(x)
  eq <- deparse1(eq)

  binary_from_prob_first(eq, type, lvl)
}
