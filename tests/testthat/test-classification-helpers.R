# Tests for classification helper functions

test_that("backtick wraps variable names", {
  expect_identical(orbital:::backtick("x"), "`x`")
  expect_identical(orbital:::backtick(c("a", "b")), c("`a`", "`b`"))
  expect_identical(orbital:::backtick("var with space"), "`var with space`")
})

test_that("binary_from_prob returns correct structure for class only", {
  result <- orbital:::binary_from_prob("0.7", "class", c("no", "yes"))

  expect_identical(
    result,
    c(
      orbital_tmp_class_name = 'dplyr::case_when(0.7 > 0.5 ~ "yes", .default = "no")'
    )
  )
})

test_that("binary_from_prob returns correct structure for prob only", {
  result <- orbital:::binary_from_prob("0.7", "prob", c("no", "yes"))

  expect_identical(
    result,
    c(orbital_tmp_prob_name1 = "1 - (0.7)", orbital_tmp_prob_name2 = "0.7")
  )
})

test_that("binary_from_prob returns both class and prob", {
  result <- orbital:::binary_from_prob(
    "0.7",
    c("class", "prob"),
    c("no", "yes")
  )

  expect_identical(
    result,
    c(
      orbital_tmp_class_name = 'dplyr::case_when(0.7 > 0.5 ~ "yes", .default = "no")',
      orbital_tmp_prob_name1 = "1 - (0.7)",
      orbital_tmp_prob_name2 = "0.7"
    )
  )
})

test_that("binary_from_prob_first returns correct structure", {
  result <- orbital:::binary_from_prob_first(
    "0.7",
    c("class", "prob"),
    c("no", "yes")
  )

  expect_identical(
    result,
    c(
      orbital_tmp_class_name = 'dplyr::case_when(0.7 > 0.5 ~ "no", .default = "yes")',
      orbital_tmp_prob_name1 = "0.7",
      orbital_tmp_prob_name2 = "1 - (0.7)"
    )
  )
})

test_that("softmax_class generates correct case_when for 2 classes", {
  result <- orbital:::softmax_class(c("a", "b"))

  expect_identical(result, 'dplyr::case_when(`a` >= `b` ~ "a", .default = "b")')
})

test_that("softmax_class generates correct case_when for 3 classes", {
  result <- orbital:::softmax_class(c("a", "b", "c"))

  expect_identical(
    result,
    'dplyr::case_when(`a` >= `b` & `a` >= `c` ~ "a", `b` >= `a` & `b` >= `c` ~ "b", .default = "c")'
  )
})

test_that("softmax_class handles special characters in level names", {
  result <- orbital:::softmax_class(c("class one", "class two"))

  expect_identical(
    result,
    'dplyr::case_when(`class one` >= `class two` ~ "class one", .default = "class two")'
  )
})

test_that("multiclass_from_logits returns correct structure for class only", {
  result <- orbital:::multiclass_from_logits(
    c("1.0", "2.0", "3.0"),
    "class",
    c("a", "b", "c")
  )

  expect_identical(
    result,
    c(
      a = "1.0",
      b = "2.0",
      c = "3.0",
      orbital_tmp_class_name = 'dplyr::case_when(`a` >= `b` & `a` >= `c` ~ "a", `b` >= `a` & `b` >= `c` ~ "b", .default = "c")'
    )
  )
})

test_that("multiclass_from_logits returns correct structure for prob only", {
  result <- orbital:::multiclass_from_logits(
    c("x", "y", "z"),
    "prob",
    c("a", "b", "c")
  )

  expect_identical(
    result,
    c(
      a = "x",
      b = "y",
      c = "z",
      norm = "exp(`a`) + exp(`b`) + exp(`c`)",
      orbital_tmp_prob_name1 = "exp(`a`) / norm",
      orbital_tmp_prob_name2 = "exp(`b`) / norm",
      orbital_tmp_prob_name3 = "exp(`c`) / norm"
    )
  )
})

test_that("multiclass_from_votes returns correct structure for prob only", {
  result <- orbital:::multiclass_from_votes(
    c("5", "3", "2"),
    "prob",
    c("a", "b", "c"),
    10
  )

  expect_identical(
    result,
    c(
      a = "5",
      b = "3",
      c = "2",
      orbital_tmp_prob_name1 = "(`a`) / 10",
      orbital_tmp_prob_name2 = "(`b`) / 10",
      orbital_tmp_prob_name3 = "(`c`) / 10"
    )
  )
})

test_that("multiclass_from_prob_avg returns correct structure for prob only", {
  result <- orbital:::multiclass_from_prob_avg(
    c("0.5", "0.3", "0.2"),
    "prob",
    c("a", "b", "c"),
    5
  )

  expect_identical(
    result,
    c(
      a = "0.5",
      b = "0.3",
      c = "0.2",
      orbital_tmp_prob_name1 = "(`a`) / 5",
      orbital_tmp_prob_name2 = "(`b`) / 5",
      orbital_tmp_prob_name3 = "(`c`) / 5"
    )
  )
})

test_that("sum_tree_expressions sums and deparses correctly", {
  tree1 <- rlang::expr(case_when(x > 1 ~ 0.5, .default = 0.3))
  tree2 <- rlang::expr(case_when(x > 2 ~ 0.6, .default = 0.4))

  class_trees <- list(
    "a" = list(tree1, tree2),
    "b" = list(tree1)
  )

  result <- orbital:::sum_tree_expressions(class_trees)

  expect_identical(
    result,
    c(
      a = "(case_when(x > 1 ~ 0.5, .default = 0.29999999999999999)) + (case_when(x > 2 ~ 0.59999999999999998, .default = 0.40000000000000002))",
      b = "(case_when(x > 1 ~ 0.5, .default = 0.29999999999999999))"
    )
  )
})

test_that("format_separate_trees returns correct structure", {
  tree1 <- rlang::expr(case_when(x > 1 ~ 10, .default = 5))
  tree2 <- rlang::expr(case_when(x > 2 ~ 20, .default = 15))
  tree3 <- rlang::expr(case_when(x > 3 ~ 30, .default = 25))

  result <- orbital:::format_separate_trees(list(tree1, tree2, tree3), ".pred")

  expect_length(result, 4)
  expect_named(
    result,
    c(".pred_tree_1", ".pred_tree_2", ".pred_tree_3", ".pred")
  )
  expect_identical(
    result[[".pred"]],
    "`.pred_tree_1` + `.pred_tree_2` + `.pred_tree_3`"
  )
})

test_that("format_separate_trees uses correct zero-padding", {
  trees <- lapply(1:100, function(i) rlang::expr(!!i))

  result <- orbital:::format_separate_trees(trees, ".pred")

  expect_length(result, 101)
  expect_true(".pred_tree_001" %in% names(result))
  expect_true(".pred_tree_100" %in% names(result))
  expect_false(".pred_tree_1" %in% names(result))
})

test_that("format_separate_trees works with custom prefix", {
  tree1 <- rlang::expr(case_when(x > 1 ~ 10, .default = 5))
  tree2 <- rlang::expr(case_when(x > 2 ~ 20, .default = 15))

  result <- orbital:::format_separate_trees(list(tree1, tree2), "my_model")

  expect_named(result, c("my_model_tree_1", "my_model_tree_2", "my_model"))
  expect_identical(
    result[["my_model"]],
    "`my_model_tree_1` + `my_model_tree_2`"
  )
})

test_that("format_separate_trees handles single tree", {
  tree1 <- rlang::expr(case_when(x > 1 ~ 10, .default = 5))

  result <- orbital:::format_separate_trees(list(tree1), ".pred")

  expect_length(result, 2)
  expect_named(result, c(".pred_tree_1", ".pred"))
  expect_identical(result[[".pred"]], "`.pred_tree_1`")
})

test_that("format_separate_trees preserves numeric precision", {
  tree <- rlang::expr(case_when(
    x > 1.23456789012345678 ~ 0.98765432109876543,
    .default = 0
  ))

  result <- orbital:::format_separate_trees(list(tree), ".pred")

  # Verify high precision is preserved (at least 15 significant digits)
  expect_match(result[[1]], "1\\.234567890123456")
  expect_match(result[[1]], "0\\.987654321098765")
})

test_that("format_multiclass_logits_separate returns correct structure", {
  tree1 <- rlang::expr(case_when(x > 1 ~ 0.5, .default = 0.3))
  tree2 <- rlang::expr(case_when(x > 2 ~ 0.6, .default = 0.4))

  trees_split <- list(list(tree1), list(tree2))
  lvl <- c("a", "b")

  result <- orbital:::format_multiclass_logits_separate(
    trees_split,
    c("class", "prob"),
    lvl,
    ".pred"
  )

  expect_match(names(result), "_a_logit_tree_", all = FALSE)
  expect_match(names(result), "_b_logit_tree_", all = FALSE)
  expect_true(".pred_a_logit" %in% names(result))
  expect_true(".pred_b_logit" %in% names(result))
  expect_true("orbital_tmp_class_name" %in% names(result))
  expect_true("norm" %in% names(result))
})

test_that("binary_from_prob_first_with_eq returns correct structure", {
  tree_res <- c(logit_tree_1 = "case_when(...)", logit = "`logit_tree_1`")

  result <- orbital:::binary_from_prob_first_with_eq(
    tree_res,
    "1/(1 + exp(-`logit`))",
    c("class", "prob"),
    c("no", "yes")
  )

  expect_true("orbital_tmp_class_name" %in% names(result))
  expect_true("orbital_tmp_prob_name1" %in% names(result))
  expect_true("orbital_tmp_prob_name2" %in% names(result))
  expect_match(result[["orbital_tmp_class_name"]], '"no"')
})
