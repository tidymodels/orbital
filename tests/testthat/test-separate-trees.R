# Tree expressions come from tidypredict and call `case_when()` unqualified, so
# evaluate against dplyr's namespace rather than relying on it being attached.
eval_tree_eqs <- function(eqs, data) {
  for (name in names(eqs)) {
    data[[name]] <- rlang::eval_tidy(
      rlang::parse_expr(eqs[[name]]),
      data = data,
      env = asNamespace("dplyr")
    )
  }
  data
}

# The property the generic path exists to preserve: writing each tree to its own
# column and recombining computes what the collapsed single expression computes.
expect_separate_matches_collapsed <- function(
  model,
  data,
  mode = "regression"
) {
  collapsed <- orbital(model, mode = mode)
  split <- orbital(model, mode = mode, separate_trees = TRUE)

  expect_equal(
    eval_tree_eqs(split, data)[[".pred"]],
    rlang::eval_tidy(collapsed, data = data, env = asNamespace("dplyr"))
  )
}

test_that("tree_columns() does not batch at or below the batch size", {
  trees <- lapply(1:50, function(i) rlang::expr(!!i))

  res <- tree_columns(trees, ".pred")

  expect_length(res$eqs, 50)
  expect_equal(res$totals, names(res$eqs))
  expect_no_match(names(res$eqs), "_sum_", all = FALSE)
})

test_that("tree_columns() batches above the batch size and hands back the totals", {
  trees <- lapply(1:120, function(i) rlang::expr(!!i))

  res <- tree_columns(trees, ".pred")

  # 120 trees plus 3 batch totals
  expect_length(res$eqs, 123)
  expect_equal(res$totals, c(".pred_sum_1", ".pred_sum_2", ".pred_sum_3"))
  expect_equal(
    res$eqs[[".pred_sum_3"]],
    paste(
      backtick(sprintf(".pred_tree_%03d", 101:120)),
      collapse = " + "
    )
  )
})

test_that("tree_columns() zero-pads tree names to a fixed width", {
  trees <- lapply(1:100, function(i) rlang::expr(!!i))

  res <- tree_columns(trees, ".pred")

  expect_equal(names(res$eqs)[[1]], ".pred_tree_001")
  expect_equal(names(res$eqs)[[100]], ".pred_tree_100")
})

test_that("separate_trees_eqs() returns the combined column last", {
  skip_if_not_installed("randomForest")

  set.seed(1)
  model <- randomForest::randomForest(mpg ~ wt + cyl, mtcars, ntree = 3)

  res <- separate_trees_eqs(model, ".pred")

  expect_named(
    res,
    c(".pred_tree_1", ".pred_tree_2", ".pred_tree_3", ".pred")
  )
})

test_that("separate trees match the collapsed expression", {
  skip_if_not_installed("randomForest")
  skip_if_not_installed("ranger")

  set.seed(1)
  expect_separate_matches_collapsed(
    randomForest::randomForest(mpg ~ wt + cyl, mtcars, ntree = 3),
    mtcars
  )
  expect_separate_matches_collapsed(
    ranger::ranger(mpg ~ wt + cyl, mtcars, num.trees = 3),
    mtcars
  )
})

test_that("separate trees match the collapsed expression when batching", {
  skip_if_not_installed("randomForest")

  set.seed(1)
  model <- randomForest::randomForest(mpg ~ wt + cyl, mtcars, ntree = 60)

  expect_separate_matches_collapsed(model, mtcars)
  expect_match(names(separate_trees_eqs(model, ".pred")), "_sum_", all = FALSE)
})

test_that("separate trees keep the missing-value guard the collapsed path has", {
  skip_if_not_installed("randomForest")

  set.seed(1)
  model <- randomForest::randomForest(mpg ~ wt + cyl, mtcars, ntree = 3)

  incomplete <- mtcars[1:2, ]
  incomplete$wt[[1]] <- NA_real_

  eqs <- orbital(model, mode = "regression", separate_trees = TRUE)
  pred <- eval_tree_eqs(eqs, incomplete)[[".pred"]]

  # The second row still scores, so the guard is not simply blanking the column.
  expect_equal(is.na(pred), c(TRUE, FALSE))
})
