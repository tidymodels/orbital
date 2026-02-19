# Tests for classification helper functions

test_that("backtick wraps variable names", {
  expect_equal(orbital:::backtick("x"), "`x`")
  expect_equal(orbital:::backtick(c("a", "b")), c("`a`", "`b`"))
  expect_equal(orbital:::backtick("var with space"), "`var with space`")
})

test_that("binary_from_prob returns correct structure for class only", {
  result <- orbital:::binary_from_prob("0.7", "class", c("no", "yes"))

  expect_named(result, "orbital_tmp_class_name")
  expect_true(grepl("case_when", result))
  expect_true(grepl("0.7 > 0.5", result))
  expect_true(grepl('"yes"', result))
  expect_true(grepl('"no"', result))
})

test_that("binary_from_prob returns correct structure for prob only", {
  result <- orbital:::binary_from_prob("0.7", "prob", c("no", "yes"))

  expect_named(result, c("orbital_tmp_prob_name1", "orbital_tmp_prob_name2"))
  expect_equal(as.character(result["orbital_tmp_prob_name1"]), "1 - (0.7)")
  expect_equal(as.character(result["orbital_tmp_prob_name2"]), "0.7")
})

test_that("binary_from_prob returns both class and prob", {
  result <- orbital:::binary_from_prob(
    "0.7",
    c("class", "prob"),
    c("no", "yes")
  )

  expect_length(result, 3)
  expect_true("orbital_tmp_class_name" %in% names(result))
  expect_true("orbital_tmp_prob_name1" %in% names(result))
  expect_true("orbital_tmp_prob_name2" %in% names(result))
})

test_that("binary_from_prob_first returns correct structure", {
  result <- orbital:::binary_from_prob_first(
    "0.7",
    c("class", "prob"),
    c("no", "yes")
  )

  # Class prediction should be first level when prob > 0.5
  expect_true(grepl('"no"', result["orbital_tmp_class_name"]))

  # Prob order is reversed from binary_from_prob
  expect_equal(as.character(result["orbital_tmp_prob_name1"]), "0.7")
  expect_equal(as.character(result["orbital_tmp_prob_name2"]), "1 - (0.7)")
})

test_that("softmax_class generates correct case_when for 2 classes", {
  result <- orbital:::softmax_class(c("a", "b"))

  expect_true(grepl("case_when", result))
  expect_true(grepl("`a` >= `b`", result))
  expect_true(grepl('"a"', result))
  expect_true(grepl('.default = "b"', result))
})

test_that("softmax_class generates correct case_when for 3 classes", {
  result <- orbital:::softmax_class(c("a", "b", "c"))

  expect_true(grepl("case_when", result))
  expect_true(grepl("`a` >= `b` & `a` >= `c`", result))
  expect_true(grepl("`b` >= `a` & `b` >= `c`", result))
  expect_true(grepl('.default = "c"', result))
})

test_that("softmax_class uses >= for tie-breaking", {
  result <- orbital:::softmax_class(c("a", "b"))

  # Should use >= not > so first class wins ties

  expect_true(grepl(">=", result))
  expect_false(grepl("`a` > `b`", result))
})

test_that("multiclass_from_logits returns correct structure for class only", {
  logits <- c("1.0", "2.0", "3.0")
  result <- orbital:::multiclass_from_logits(logits, "class", c("a", "b", "c"))

  expect_true("a" %in% names(result))
  expect_true("b" %in% names(result))
  expect_true("c" %in% names(result))
  expect_true("orbital_tmp_class_name" %in% names(result))
  expect_false("norm" %in% names(result))
})

test_that("multiclass_from_logits returns correct structure for prob only", {
  logits <- c("1.0", "2.0", "3.0")
  result <- orbital:::multiclass_from_logits(logits, "prob", c("a", "b", "c"))

  expect_true("a" %in% names(result))
  expect_true("b" %in% names(result))
  expect_true("c" %in% names(result))
  expect_true("norm" %in% names(result))
  expect_true("orbital_tmp_prob_name1" %in% names(result))
  expect_true("orbital_tmp_prob_name2" %in% names(result))
  expect_true("orbital_tmp_prob_name3" %in% names(result))
  expect_false("orbital_tmp_class_name" %in% names(result))
})

test_that("multiclass_from_logits generates softmax normalization", {
  logits <- c("x", "y", "z")
  result <- orbital:::multiclass_from_logits(logits, "prob", c("a", "b", "c"))

  # Check norm calculation
  expect_true(grepl("exp\\(`a`\\)", result["norm"]))
  expect_true(grepl("exp\\(`b`\\)", result["norm"]))
  expect_true(grepl("exp\\(`c`\\)", result["norm"]))

  # Check probability calculations
  expect_true(grepl("exp\\(`a`\\) / norm", result["orbital_tmp_prob_name1"]))
})

test_that("multiclass_from_votes returns correct structure", {
  votes <- c("5", "3", "2")
  result <- orbital:::multiclass_from_votes(
    votes,
    c("class", "prob"),
    c("a", "b", "c"),
    10
  )

  expect_true("a" %in% names(result))
  expect_true("b" %in% names(result))
  expect_true("c" %in% names(result))
  expect_true("orbital_tmp_class_name" %in% names(result))
  expect_true("orbital_tmp_prob_name1" %in% names(result))
})

test_that("multiclass_from_votes divides by n_trees", {
  votes <- c("5", "3", "2")
  result <- orbital:::multiclass_from_votes(votes, "prob", c("a", "b", "c"), 10)

  expect_true(grepl("/ 10", result["orbital_tmp_prob_name1"]))
  expect_true(grepl("/ 10", result["orbital_tmp_prob_name2"]))
  expect_true(grepl("/ 10", result["orbital_tmp_prob_name3"]))
})

test_that("multiclass_from_prob_avg returns correct structure", {
  prob_sums <- c("0.5", "0.3", "0.2")
  result <- orbital:::multiclass_from_prob_avg(
    prob_sums,
    c("class", "prob"),
    c("a", "b", "c"),
    10
  )

  expect_true("a" %in% names(result))
  expect_true("b" %in% names(result))
  expect_true("c" %in% names(result))
  expect_true("orbital_tmp_class_name" %in% names(result))
  expect_true("orbital_tmp_prob_name1" %in% names(result))
})

test_that("multiclass_from_prob_avg divides by n_trees", {
  prob_sums <- c("0.5", "0.3", "0.2")
  result <- orbital:::multiclass_from_prob_avg(
    prob_sums,
    "prob",
    c("a", "b", "c"),
    5
  )

  expect_true(grepl("/ 5", result["orbital_tmp_prob_name1"]))
  expect_true(grepl("/ 5", result["orbital_tmp_prob_name2"]))
  expect_true(grepl("/ 5", result["orbital_tmp_prob_name3"]))
})

test_that("helpers handle special characters in level names", {
  # Level names with spaces
  result <- orbital:::softmax_class(c("class one", "class two"))
  expect_true(grepl("`class one`", result))
  expect_true(grepl("`class two`", result))
})

test_that("sum_tree_expressions sums and deparses correctly", {
  # Create mock tree expressions
  tree1 <- rlang::expr(case_when(x > 1 ~ 0.5, .default = 0.3))
  tree2 <- rlang::expr(case_when(x > 2 ~ 0.6, .default = 0.4))

  class_trees <- list(
    "a" = list(tree1, tree2),
    "b" = list(tree1)
  )

  result <- orbital:::sum_tree_expressions(class_trees)

  expect_named(result, c("a", "b"))
  expect_type(result, "character")
  # Check that expressions are joined with +

  expect_true(grepl("\\+", result["a"]))
  # Single tree should not have +
  expect_false(grepl("\\+", result["b"]))
})
