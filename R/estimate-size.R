#' Estimate orbital object size without generating it
#'
#' Estimates the character count of the orbital expression that would be
#' generated for a model, without actually generating it. This is useful during
#' hyperparameter tuning when you want to track SQL size as a metric but don't
#' want to pay the cost of generating the full orbital object for every
#' candidate model.
#'
#' @param x A fitted model object, workflow, prepped recipe, or fitted tailor.
#' @param ... Additional arguments passed to methods.
#' @param penalty For glmnet models, the penalty value (lambda) to use. If the
#'   model was fit with a single lambda, this is used by default. Otherwise,
#'   you must specify a value.
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
#' ## Supported objects
#'
#' Currently supported:
#' - Workflows (`workflow`)
#' - Recipes (`recipe`)
#' - Tailors (`tailor`)
#' - xgboost (`xgb.Booster`)
#' - lightgbm (`lgb.Booster`)
#' - catboost (`catboost.Model`)
#' - ranger (`ranger`)
#' - randomForest (`randomForest`)
#' - rpart (`rpart`)
#' - partykit (`constparty`)
#' - glm (`glm`)
#' - glmnet (`glmnet`)
#' - earth (`earth`)
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

# Shared helper for tree-based models
# Formula derived from empirical analysis of dplyr::if_else() expressions:
# - Each tree adds ~16 chars base overhead
# - Each internal node adds ~58 chars + feature name length
# - Tree combination adds ~5 chars per tree for " + " and parentheses
# - Base score addition adds ~25 chars
estimate_tree_chars <- function(n_trees, n_internal, avg_feature_len) {
  tree_chars <- 16 * n_trees + n_internal * (58 + avg_feature_len)
  combination_overhead <- 5 * n_trees
  base_overhead <- 25
  as.integer(tree_chars + combination_overhead + base_overhead)
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

  estimate_tree_chars(n_trees, n_internal, avg_feature_len)
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.lgb.Booster <- function(x, ...) {
  rlang::check_installed("lightgbm")

  model_json <- x$dump_model()
  model_info <- jsonlite::fromJSON(model_json)

  n_trees <- length(model_info$tree_info$num_leaves)
  # For a binary tree: n_internal = n_leaves - 1 per tree
  n_internal <- sum(model_info$tree_info$num_leaves - 1)

  feature_names <- model_info$feature_names
  if (length(feature_names) > 0) {
    avg_feature_len <- mean(nchar(feature_names))
  } else {
    avg_feature_len <- 5
  }

  estimate_tree_chars(n_trees, n_internal, avg_feature_len)
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.ranger <- function(x, ...) {
  rlang::check_installed("ranger")

  n_trees <- x$num.trees

  # Count internal nodes: left child != 0 indicates internal node
  n_internal <- sum(vapply(
    x$forest$child.nodeIDs,
    function(tree) sum(tree[[1]] != 0),
    integer(1)
  ))

  feature_names <- x$forest$independent.variable.names
  if (length(feature_names) > 0) {
    avg_feature_len <- mean(nchar(feature_names))
  } else {
    avg_feature_len <- 5
  }

  estimate_tree_chars(n_trees, n_internal, avg_feature_len)
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.randomForest <- function(x, ...) {
  rlang::check_installed("randomForest")

  n_trees <- x$ntree

  # Count internal nodes: leftDaughter != 0 indicates internal node
  n_internal <- sum(x$forest$leftDaughter != 0)

  # Get feature names from xlevels or fall back to generic names
  feature_names <- names(x$forest$xlevels)
  if (length(feature_names) > 0) {
    avg_feature_len <- mean(nchar(feature_names))
  } else {
    avg_feature_len <- 5
  }

  estimate_tree_chars(n_trees, n_internal, avg_feature_len)
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.rpart <- function(x, ...) {
  n_internal <- sum(x$frame$var != "<leaf>")

  feature_names <- unique(x$frame$var[x$frame$var != "<leaf>"])
  if (length(feature_names) > 0) {
    avg_feature_len <- mean(nchar(feature_names))
  } else {
    avg_feature_len <- 5
  }

  estimate_tree_chars(1L, n_internal, avg_feature_len)
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.constparty <- function(x, ...) {
  rlang::check_installed("partykit")

  n_total <- length(x)
  n_leaves <- length(partykit::nodeids(x, terminal = TRUE))
  n_internal <- n_total - n_leaves

  # Use all predictor variable names from the data
  feature_names <- names(x$data)
  # Remove response variable (first column is typically response)
  if (length(feature_names) > 1) {
    feature_names <- feature_names[-1]
  }
  if (length(feature_names) > 0) {
    avg_feature_len <- mean(nchar(feature_names))
  } else {
    avg_feature_len <- 5
  }

  estimate_tree_chars(1L, n_internal, avg_feature_len)
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.catboost.Model <- function(x, ...) {
  rlang::check_installed("catboost")

  # Use tidypredict's parse_model which is fast (~4ms)
  pm <- tidypredict::parse_model(x)

  n_trees <- pm$general$niter
  # For symmetric/oblivious trees, all trees have the same number of leaves
  n_leaves_per_tree <- length(pm$trees[[1]])
  n_internal <- n_trees * (n_leaves_per_tree - 1)

  feature_names <- pm$general$feature_names
  if (length(feature_names) > 0) {
    avg_feature_len <- mean(nchar(feature_names))
  } else {
    avg_feature_len <- 5
  }

  estimate_tree_chars(n_trees, n_internal, avg_feature_len)
}

# Shared helper for linear models
# Formula derived from empirical analysis:
# - Intercept adds ~20 chars
# - Each coefficient term "(feature * coef) + " adds ~29 chars + feature name length
estimate_linear_chars <- function(n_coefs, avg_feature_len) {
  intercept_chars <- 20
  # n_coefs includes intercept, so we have (n_coefs - 1) feature terms
  feature_terms <- (n_coefs - 1) * (29 + avg_feature_len)
  as.integer(intercept_chars + feature_terms)
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.glm <- function(x, ...) {
  coefs <- stats::coef(x)
  n_coefs <- length(coefs)

  # Exclude intercept from feature name calculation
  feature_names <- names(coefs)
  feature_names <- feature_names[feature_names != "(Intercept)"]
  if (length(feature_names) > 0) {
    avg_feature_len <- mean(nchar(feature_names))
  } else {
    avg_feature_len <- 5
  }

  estimate_linear_chars(n_coefs, avg_feature_len)
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.lm <- estimate_orbital_size.glm

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.glmnet <- function(x, ..., penalty = NULL) {
  rlang::check_installed("glmnet")

  if (is.null(penalty)) {
    if (length(x$lambda) != 1) {
      cli::cli_abort(
        c(
          "glmnet model has multiple penalty values.",
          "i" = "Specify a single {.arg penalty} value."
        )
      )
    }
    penalty <- x$lambda
  }

  coefs <- stats::coef(x, s = penalty)
  coef_values <- as.numeric(coefs)
  coef_names <- rownames(coefs)

  # Count non-zero coefficients
  non_zero_idx <- which(coef_values != 0)
  n_coefs <- length(non_zero_idx)

  # Only count features with non-zero coefficients
  feature_names <- coef_names[non_zero_idx]
  feature_names <- feature_names[feature_names != "(Intercept)"]

  if (length(feature_names) > 0) {
    avg_feature_len <- mean(nchar(feature_names))
  } else {
    avg_feature_len <- 5
  }

  estimate_linear_chars(n_coefs, avg_feature_len)
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.earth <- function(x, ...) {
  rlang::check_installed("earth")

  coefs <- stats::coef(x)
  n_coefs <- length(coefs)

  # Earth coefficient names include hinge functions like "h(disp-145)"
  feature_names <- names(coefs)
  feature_names <- feature_names[feature_names != "(Intercept)"]
  if (length(feature_names) > 0) {
    avg_feature_len <- mean(nchar(feature_names))
  } else {
    avg_feature_len <- 5
  }

  estimate_linear_chars(n_coefs, avg_feature_len)
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.recipe <- function(x, ...) {
  rlang::check_installed("recipes")

  if (!recipes::fully_trained(x)) {
    cli::cli_abort("recipe must be fully trained.")
  }

  total_chars <- 0L

  for (step in x$steps) {
    if (step$skip) {
      next
    }
    step_chars <- estimate_step_chars(step)
    total_chars <- total_chars + step_chars
  }

  total_chars
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.workflow <- function(x, ...) {
  rlang::check_installed("workflows")

  if (!workflows::is_trained_workflow(x)) {
    cli::cli_abort("{.arg x} must be a fully trained {.cls workflow}.")
  }

  total_chars <- 0L

  # Estimate recipe contribution
  preprocessor <- workflows::extract_preprocessor(x)
  if (inherits(preprocessor, "recipe")) {
    recipe_fit <- workflows::extract_recipe(x)
    total_chars <- total_chars + estimate_orbital_size(recipe_fit, ...)
  }

  # Estimate model contribution
  model_fit <- workflows::extract_fit_parsnip(x)
  model_chars <- tryCatch(
    estimate_orbital_size(model_fit$fit, ...),
    error = function(e) {
      # Fall back to 0 if model type not supported
      0L
    }
  )
  total_chars <- total_chars + model_chars

  # Estimate tailor contribution
  if ("tailor" %in% names(x$post$actions)) {
    tailor_fit <- workflows::extract_tailor(x)
    total_chars <- total_chars + estimate_orbital_size(tailor_fit, ...)
  }

  total_chars
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.tailor <- function(x, ...) {
  rlang::check_installed("tailor")

  if (is.null(x$columns)) {
    cli::cli_abort("{.arg x} must be a fitted {.cls tailor}.")
  }

  total_chars <- 0L

  for (adj in x$adjustments) {
    adj_chars <- estimate_adj_chars(adj)
    total_chars <- total_chars + adj_chars
  }

  total_chars
}

# Step estimation generic and methods ----------------------------------------

# Internal generic for estimating step character counts
estimate_step_chars <- function(x, ...) {
  UseMethod("estimate_step_chars")
}

# Default: estimate based on number of columns affected
# Most steps produce ~40 chars per column as a rough baseline
estimate_step_chars.default <- function(x, ...) {
  n_cols <- length(x$columns %||% 0L)
  as.integer(n_cols * 40)
}

# Adjustment estimation generic and methods -----------------------------------

# Internal generic for estimating adjustment character counts
estimate_adj_chars <- function(x, ...) {
  UseMethod("estimate_adj_chars")
}

# Default: most adjustments produce ~80 chars for a case_when expression
estimate_adj_chars.default <- function(x, ...) {
  80L
}
