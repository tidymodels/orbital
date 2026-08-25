# Writes each tree to its own column, so that a database can evaluate them in
# parallel, and returns those columns along with the names that stand in for
# the trees afterwards.
#
# Summation is batched so that no single expression is deep enough to hit an
# engine's parser limit. Substituting the batch totals for the trees is safe
# because every `tidypredict_combine_trees()` method sums the list it is handed
# and takes any tree count it needs from the model rather than from
# `length(trees)`.
tree_columns <- function(trees, prefix, batch_size = 50) {
  n <- length(trees)
  width <- nchar(as.character(n))
  tree_names <- sprintf(paste0(prefix, "_tree_%0", width, "d"), seq_len(n))

  tree_strs <- vapply(
    trees,
    function(e) deparse1(e, control = "digits17"),
    character(1)
  )

  out <- stats::setNames(tree_strs, tree_names)

  if (n <= batch_size) {
    return(list(eqs = out, totals = tree_names))
  }

  batch_indices <- split(seq_len(n), ceiling(seq_len(n) / batch_size))
  batch_width <- nchar(as.character(length(batch_indices)))
  batch_names <- sprintf(
    paste0(prefix, "_sum_%0", batch_width, "d"),
    seq_along(batch_indices)
  )

  for (i in seq_along(batch_indices)) {
    batch_sum <- paste(
      backtick(tree_names[batch_indices[[i]]]),
      collapse = " + "
    )
    out <- c(out, stats::setNames(batch_sum, batch_names[i]))
  }

  list(eqs = out, totals = batch_names)
}

# The generic `separate_trees = TRUE` path. orbital owns splitting the trees
# into columns and batching them; tidypredict owns the arithmetic that turns
# them back into a prediction, which differs by backend and used to be
# reimplemented here as string surgery.
separate_trees_eqs <- function(x, prefix, trees = NULL, batch_size = 50) {
  trees <- trees %||% tidypredict::tidypredict_trees(x)

  if (length(trees) == 0) {
    return(stats::setNames("0", prefix))
  }

  cols <- tree_columns(trees, prefix, batch_size)
  combined <- tidypredict::tidypredict_combine_trees(
    x,
    rlang::syms(cols$totals)
  )

  c(
    cols$eqs,
    stats::setNames(deparse1(combined, control = "digits17"), prefix)
  )
}
