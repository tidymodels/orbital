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
  # These exercise the model methods directly rather than through a fitted
  # workflow, so they mark themselves the way `orbital.model_fit()` does.
  collapsed <- orbital(model, mode = mode, .from_parsnip = TRUE)
  split <- orbital(
    model,
    mode = mode,
    separate_trees = TRUE,
    .from_parsnip = TRUE
  )

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

  eqs <- orbital(
    model,
    mode = "regression",
    separate_trees = TRUE,
    .from_parsnip = TRUE
  )
  pred <- eval_tree_eqs(eqs, incomplete)[[".pred"]]

  # The second row still scores, so the guard is not simply blanking the column.
  expect_equal(is.na(pred), c(TRUE, FALSE))
})

# The fallback path: models orbital has no method of its own for, whose trees
# come from tidypredict's extractors. These go through a fitted parsnip model
# rather than a bare fit, since that is where the fallback lives.
expect_fallback_separate_matches_collapsed <- function(fit, data) {
  collapsed <- orbital(fit)
  split <- orbital(fit, separate_trees = TRUE)

  expect_gt(length(split), length(collapsed))
  expect_equal(
    eval_tree_eqs(split, data)[[".pred"]],
    eval_tree_eqs(collapsed, data)[[".pred"]]
  )
}

test_that("separate trees work for rand_forest(aorsf)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("aorsf")

  set.seed(1)
  spec <- parsnip::set_engine(
    parsnip::rand_forest(mode = "regression", trees = 3),
    "aorsf"
  )
  fit <- parsnip::fit(spec, mpg ~ wt + cyl + disp, mtcars)

  # aorsf splits on observed values, so a training row can sit exactly on a
  # split boundary. Jittering keeps both paths off those ties.
  set.seed(99)
  data <- mtcars
  data[] <- lapply(mtcars, function(x) x + stats::rnorm(length(x), 0, 0.01))

  expect_fallback_separate_matches_collapsed(fit, data)
})

test_that("separate trees work for rand_forest(partykit)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("partykit")

  set.seed(1)
  spec <- parsnip::set_engine(
    parsnip::rand_forest(mode = "regression", trees = 3),
    "partykit"
  )
  fit <- parsnip::fit(spec, mpg ~ wt + cyl, mtcars)

  expect_fallback_separate_matches_collapsed(fit, mtcars)
})

# Batching divides the trees into subtotals, so the divisor of an averaging
# ensemble has to come from the model rather than from the number of subtotals
# handed back.
test_that("separate trees match the collapsed expression when batching a forest that averages", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("partykit")

  set.seed(1)
  spec <- parsnip::set_engine(
    parsnip::rand_forest(mode = "regression", trees = 60),
    "partykit"
  )
  fit <- parsnip::fit(spec, mpg ~ wt + cyl, mtcars)

  split <- orbital(fit, separate_trees = TRUE)

  expect_match(names(split), "_sum_", all = FALSE)
  expect_equal(
    eval_tree_eqs(split, mtcars)[[".pred"]],
    eval_tree_eqs(orbital(fit), mtcars)[[".pred"]]
  )
})

test_that("separate_trees is ignored for a fallback model with no trees", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("nnet")

  set.seed(1)
  fit <- parsnip::fit(
    parsnip::set_engine(parsnip::mlp(mode = "regression"), "nnet"),
    mpg ~ wt + cyl,
    mtcars
  )

  expect_identical(orbital(fit, separate_trees = TRUE), orbital(fit))
})
