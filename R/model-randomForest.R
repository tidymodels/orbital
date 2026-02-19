#' @export
orbital.randomForest <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL
) {
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (mode == "classification") {
    class_trees <- tidypredict::.extract_rf_classprob(x)
    n_trees <- x$ntree

    # Sum tree expressions for each class (voting)
    # Use digits17 control to preserve full numeric precision in split values
    vote_sums <- vapply(
      names(class_trees),
      function(cls) {
        trees <- class_trees[[cls]]
        tree_strs <- vapply(
          trees,
          function(e) deparse1(e, control = "digits17"),
          character(1)
        )
        paste0("(", tree_strs, ")", collapse = " + ")
      },
      character(1)
    )

    res <- multiclass_from_votes(vote_sums, type, lvl, n_trees)
  } else if (mode == "regression") {
    res <- tidypredict::tidypredict_fit(x)
  }
  res
}
