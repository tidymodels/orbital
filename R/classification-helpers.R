# Shared helper functions for classification models

# Helper to backtick variable names for use in expressions
backtick <- function(x) {
  paste0("`", x, "`")
}

# Binary classification from a single probability expression
# Assumes: eq is P(second level)
binary_from_prob <- function(eq, type, lvl) {
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
    res <- c(
      res,
      orbital_tmp_prob_name1 = glue::glue("1 - ({eq})"),
      orbital_tmp_prob_name2 = glue::glue("{eq}")
    )
  }
  res
}

# Binary classification from a single probability expression
# Assumes: eq is P(first level)
binary_from_prob_first <- function(eq, type, lvl) {
  res <- NULL
  if ("class" %in% type) {
    levels <- glue::double_quote(lvl)
    res <- c(
      res,
      orbital_tmp_class_name = glue::glue(
        "dplyr::case_when({eq} > 0.5 ~ {levels[1]}, .default = {levels[2]})"
      )
    )
  }
  if ("prob" %in% type) {
    res <- c(
      res,
      orbital_tmp_prob_name1 = glue::glue("{eq}"),
      orbital_tmp_prob_name2 = glue::glue("1 - ({eq})")
    )
  }
  res
}

# Generate class selection from logits/scores (pick class with max value)
# Uses >= to break ties in favor of earlier classes (matching randomForest behavior)
softmax_class <- function(lvl) {
  lvl_bt <- backtick(lvl)
  res <- character(0)
  for (i in seq(1, length(lvl) - 1)) {
    line <- glue::glue("{lvl_bt[i]} >= {lvl_bt[-i]}")
    line <- glue::glue_collapse(line, sep = " & ")
    line <- glue::glue("{line} ~ {glue::double_quote(lvl[i])}")
    res[i] <- line
  }

  res <- glue::glue_collapse(res, ", ")
  default <- glue::double_quote(lvl[length(lvl)])
  glue::glue("dplyr::case_when({res}, .default = {default})")
}

# Multiclass from logits (linear predictors before softmax)
multiclass_from_logits <- function(logit_eqs, type, lvl) {
  res <- stats::setNames(logit_eqs, lvl)
  lvl_bt <- backtick(lvl)

  if ("class" %in% type) {
    res <- c(res, orbital_tmp_class_name = softmax_class(lvl))
  }
  if ("prob" %in% type) {
    norm_eq <- glue::glue_collapse(glue::glue("exp({lvl_bt})"), sep = " + ")
    prob_eqs <- glue::glue("exp({lvl_bt}) / norm")
    names(prob_eqs) <- paste0("orbital_tmp_prob_name", seq_along(lvl))
    res <- c(res, "norm" = norm_eq, prob_eqs)
  }
  res
}

# Multiclass from vote counts
multiclass_from_votes <- function(vote_eqs, type, lvl, n_trees) {
  res <- stats::setNames(vote_eqs, lvl)
  lvl_bt <- backtick(lvl)

  if ("class" %in% type) {
    res <- c(res, orbital_tmp_class_name = softmax_class(lvl))
  }
  if ("prob" %in% type) {
    prob_eqs <- glue::glue("({lvl_bt}) / {n_trees}")
    names(prob_eqs) <- paste0("orbital_tmp_prob_name", seq_along(lvl))
    res <- c(res, prob_eqs)
  }
  res
}

# Multiclass from probability averages
multiclass_from_prob_avg <- function(prob_sum_eqs, type, lvl, n_trees) {
  res <- stats::setNames(prob_sum_eqs, lvl)
  lvl_bt <- backtick(lvl)

  if ("prob" %in% type) {
    prob_eqs <- glue::glue("({lvl_bt}) / {n_trees}")
    names(prob_eqs) <- paste0("orbital_tmp_prob_name", seq_along(lvl))
    res <- c(res, prob_eqs)
  }
  if ("class" %in% type) {
    res <- c(res, orbital_tmp_class_name = softmax_class(lvl))
  }
  res
}

# Collapse stump trees (single-leaf) into a constant value
# Used by xgboost, lightgbm, catboost for multiclass
collapse_stumps <- function(x) {
  stump_ind <- lengths(x) == 2

  stumps <- x[stump_ind]
  trees <- x[!stump_ind]

  stump_values <- lapply(stumps, function(x) eval(x[[2]][[3]]))
  stump_values <- unlist(stump_values)
  stump_values <- sum(stump_values)

  c(stump_values, trees)
}

# Sum tree expressions for each class
# Used by ranger and randomForest for classification
# Uses digits17 control to preserve full numeric precision in split values
sum_tree_expressions <- function(class_trees) {
  vapply(
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
}

# Helper for binary classification with pre-computed equation parts
# Used when separate_trees = TRUE
binary_from_prob_with_eq <- function(tree_res, prob_eq, type, lvl) {
  res <- tree_res
  if ("class" %in% type) {
    levels <- glue::double_quote(lvl)
    res <- c(
      res,
      orbital_tmp_class_name = glue::glue(
        "dplyr::case_when({prob_eq} > 0.5 ~ {levels[2]}, .default = {levels[1]})"
      )
    )
  }
  if ("prob" %in% type) {
    res <- c(
      res,
      orbital_tmp_prob_name1 = paste0("1 - (", prob_eq, ")"),
      orbital_tmp_prob_name2 = prob_eq
    )
  }
  res
}

# Helper for binary classification with pre-computed equation parts
# Used when separate_trees = TRUE, probability is P(first level)
binary_from_prob_first_with_eq <- function(tree_res, prob_eq, type, lvl) {
  res <- tree_res
  if ("class" %in% type) {
    levels <- glue::double_quote(lvl)
    res <- c(
      res,
      orbital_tmp_class_name = glue::glue(
        "dplyr::case_when({prob_eq} > 0.5 ~ {levels[1]}, .default = {levels[2]})"
      )
    )
  }
  if ("prob" %in% type) {
    res <- c(
      res,
      orbital_tmp_prob_name1 = prob_eq,
      orbital_tmp_prob_name2 = paste0("1 - (", prob_eq, ")")
    )
  }
  res
}

# Format classification trees separately for ranger/randomForest
# Used when separate_trees = TRUE for classification based on votes/sums
format_classification_trees_separate <- function(
  class_trees,
  type,
  lvl,
  prefix,
  suffix,
  n_trees
) {
  res <- character()
  for (cls in names(class_trees)) {
    cls_trees <- class_trees[[cls]]
    cls_prefix <- paste0(prefix, "_", cls, "_", suffix)
    cls_res <- format_separate_trees(cls_trees, cls_prefix)
    res <- c(res, cls_res)
  }

  # Add probability calculations (divide by n_trees) and class selection
  lvl_names <- paste0(prefix, "_", lvl, "_", suffix)
  lvl_bt <- backtick(lvl_names)

  if ("prob" %in% type) {
    prob_eqs <- paste0("(", lvl_bt, ") / ", n_trees)
    names(prob_eqs) <- paste0("orbital_tmp_prob_name", seq_along(lvl))
    res <- c(res, prob_eqs)
  }
  if ("class" %in% type) {
    res <- c(
      res,
      orbital_tmp_class_name = softmax_class_from_names(lvl_names, lvl)
    )
  }

  res
}

# Generate softmax class selection using custom column names
# Used when separate_trees = TRUE for classification
softmax_class_from_names <- function(col_names, lvl) {
  col_bt <- backtick(col_names)
  res <- character(0)
  for (i in seq(1, length(lvl) - 1)) {
    comparisons <- paste0(col_bt[i], " >= ", col_bt[-i])
    line <- paste(comparisons, collapse = " & ")
    line <- paste0(line, " ~ ", glue::double_quote(lvl[i]))
    res[i] <- line
  }

  res <- paste(res, collapse = ", ")
  default <- glue::double_quote(lvl[length(lvl)])
  paste0("dplyr::case_when(", res, ", .default = ", default, ")")
}

# Format multiclass trees separately and add softmax probability calculations
# Used when separate_trees = TRUE for logit-based multiclass (xgboost, lightgbm, catboost)
format_multiclass_logits_separate <- function(trees_split, type, lvl, prefix) {
  res <- character()
  for (i in seq_along(lvl)) {
    cls <- lvl[i]
    cls_trees <- trees_split[[i]]
    cls_prefix <- paste0(prefix, "_", cls, "_logit")
    cls_res <- format_separate_trees(cls_trees, cls_prefix)
    res <- c(res, cls_res)
  }

  # Add class selection and probability calculations
  lvl_logit_names <- paste0(prefix, "_", lvl, "_logit")
  lvl_bt <- backtick(lvl_logit_names)

  if ("class" %in% type) {
    res <- c(
      res,
      orbital_tmp_class_name = softmax_class_from_names(lvl_logit_names, lvl)
    )
  }
  if ("prob" %in% type) {
    norm_eq <- paste(paste0("exp(", lvl_bt, ")"), collapse = " + ")
    prob_eqs <- paste0("exp(", lvl_bt, ") / norm")
    names(prob_eqs) <- paste0("orbital_tmp_prob_name", seq_along(lvl))
    res <- c(res, "norm" = norm_eq, prob_eqs)
  }

  res
}

# Format trees as separate expressions for database parallelization
# Returns named character vector: individual tree expressions + final sum
# Used when separate_trees = TRUE for regression models
# Batches summation in groups of 50 to avoid expression depth limits in databases
format_separate_trees <- function(trees, prefix = ".pred", batch_size = 50) {
  n <- length(trees)

  if (n == 0) {
    return(stats::setNames("0", prefix))
  }
  width <- nchar(as.character(n))
  tree_names <- sprintf(paste0(prefix, "_tree_%0", width, "d"), seq_len(n))

  tree_strs <- vapply(
    trees,
    function(e) deparse1(e, control = "digits17"),
    character(1)
  )

  out <- stats::setNames(tree_strs, tree_names)

  # Batch summation to avoid expression depth limits
  if (n <= batch_size) {
    sum_expr <- paste(backtick(tree_names), collapse = " + ")
    out <- c(out, stats::setNames(sum_expr, prefix))
  } else {
    # Split into batches
    batch_indices <- split(seq_len(n), ceiling(seq_len(n) / batch_size))
    n_batches <- length(batch_indices)
    batch_width <- nchar(as.character(n_batches))
    batch_names <- sprintf(
      paste0(prefix, "_sum_%0", batch_width, "d"),
      seq_len(n_batches)
    )

    # Create batch sum expressions
    for (i in seq_along(batch_indices)) {
      idx <- batch_indices[[i]]
      batch_sum <- paste(backtick(tree_names[idx]), collapse = " + ")
      out <- c(out, stats::setNames(batch_sum, batch_names[i]))
    }

    # Final sum of batches
    final_sum <- paste(backtick(batch_names), collapse = " + ")
    out <- c(out, stats::setNames(final_sum, prefix))
  }

  out
}
