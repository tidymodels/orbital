#' Estimate orbital object size without generating it
#'
#' Estimates the character count of the orbital expression that would be
#' generated for a model, without actually generating it. This is useful during
#' hyperparameter tuning when you want to track SQL size as a metric but don't
#' want to pay the cost of generating the full orbital object for every
#' candidate model.
#'
#' @param x A fitted model object.
#' @param ... Additional arguments passed to methods.
#'
#' @returns An integer estimate of the total character count of the orbital
#'   expression.
#'
#' @details
#' The estimation uses model metadata (tree structure, number of parameters,
#' feature names) to approximate the size of the resulting orbital expression.
#' The estimates are typically within 5-10% of the actual size.
#'
#' For tree-based models, this function is much faster than generating the full
#' orbital object because it only needs to inspect the tree structure, not
#' convert each tree to an R expression.
#'
#' ## Supported models
#'
#' Currently supported:
#' - xgboost (`xgb.Booster`)
#'
#' @seealso [orbital()] for generating orbital objects, the
#'   `vignette("sql-size")` for more on SQL size considerations.
#'
#' @examplesIf rlang::is_installed("xgboost")
#' library(xgboost)
#'
#' # Create a model
#' x <- as.matrix(mtcars[, -1])
#' y <- mtcars[, 1]
#' model <- xgboost(x = x, y = y, nrounds = 50, max_depth = 4, verbosity = 0)
#'
#' # Estimate size (fast)
#' estimate_orbital_size(model)
#'
#' @export
estimate_orbital_size <- function(x, ...) {
  UseMethod("estimate_orbital_size")
}

#' @export
estimate_orbital_size.default <- function(x, ...) {
  cli::cli_abort(
    "{.fn estimate_orbital_size} is not implemented for
    {.obj_type_friendly {x}}."
  )
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.xgb.Booster <- function(x, ...) {
  rlang::check_installed("xgboost")

  dump <- xgboost::xgb.dump(x, with_stats = FALSE)

  n_trees <- sum(startsWith(dump, "booster"))
  n_leaves <- sum(grepl("leaf=", dump, fixed = TRUE))
  n_internal <- length(dump) - n_trees - n_leaves

  # Sample internal lines to estimate average feature name length
  internal_idx <- which(grepl("<", dump, fixed = TRUE))
  if (length(internal_idx) > 50) {
    sample_idx <- internal_idx[seq(1, length(internal_idx), length.out = 50)]
  } else {
    sample_idx <- internal_idx
  }

  if (length(sample_idx) > 0) {
    features <- sub(".*\\[([^<]+)<.*", "\\1", dump[sample_idx])
    avg_feature_len <- mean(nchar(features))
  } else {
    avg_feature_len <- 5
  }

  # Formula derived from empirical analysis of dplyr::if_else() expressions:

  # - Each tree adds ~16 chars base overhead
  # - Each internal node adds ~58 chars + feature name length for the

  #   dplyr::if_else(feature < value, ..., ...) structure
  # - Tree combination adds ~5 chars per tree for " + " and parentheses
  # - Base score addition adds ~25 chars
  tree_chars <- 16 * n_trees + n_internal * (58 + avg_feature_len)

  combination_overhead <- 5 * n_trees
  base_overhead <- 25

  as.integer(tree_chars + combination_overhead + base_overhead)
}
