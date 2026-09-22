#' Estimate orbital expression character count
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
#' @param input_names For a bare `torch::nn_sequential()` model, the names of
#'   the model's input features, in order. Required, since torch tensors are
#'   positional and carry no column names.
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
#' This function aims to support all the same models and preprocessing
#' operations as [orbital()], but does not yet reach all of them. A model with
#' no estimate is an error rather than a zero, including inside a workflow,
#' since a workflow's model is usually the bulk of the expression and counting
#' it as free would report the recipe's size as the whole. If you find a case
#' where `orbital()` works but `estimate_orbital_size()` does not, please
#' [file an issue](https://github.com/tidymodels/orbital/issues).
#'
#' @seealso [orbital()] for generating orbital objects.
#'
#' @examplesIf rlang::is_installed("xgboost")
#' library(xgboost)
#'
#' # Estimate size for an xgboost model
#' x <- as.matrix(mtcars[, -1])
#' y <- mtcars[, 1]
#' model <- xgboost(
#'   x = x,
#'   y = y,
#'   nrounds = 50,
#'   max_depth = 4,
#'   verbosity = 0,
#'   nthreads = 1
#' )
#'
#' estimate_orbital_size(model)
#'
#' @examplesIf rlang::is_installed(c("recipes", "workflows", "parsnip"))
#' library(recipes)
#' library(workflows)
#' library(parsnip)
#'
#' # Estimate size for a workflow
#' rec <- recipe(mpg ~ ., data = mtcars) |>
#'   step_normalize(all_numeric_predictors())
#'
#' wf <- workflow() |>
#'   add_recipe(rec) |>
#'   add_model(linear_reg()) |>
#'   fit(mtcars)
#'
#' estimate_orbital_size(wf)
#'
#' @export
estimate_orbital_size <- function(x, ...) {
  UseMethod("estimate_orbital_size")
}

#' @export
estimate_orbital_size.default <- function(x, ...) {
  cli::cli_abort(
    c(
      "{.fn estimate_orbital_size} is not implemented for
       {.obj_type_friendly {x}}.",
      i = "Use {.fn orbital} to build the expression and measure it, or
           {.url https://github.com/tidymodels/orbital/issues} to request an
           estimate for this model."
    )
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

  # Estimate model contribution. An unsupported model is an error rather than a
  # zero: the model is usually the bulk of the expression, so counting it as
  # free reports the recipe's size as the whole workflow's. That number looks
  # ordinary, which is what makes it worse than a refusal. It is also flat
  # across hyperparameters, so tuning on it would compare candidates that the
  # estimate cannot tell apart.
  model_fit <- workflows::extract_fit_parsnip(x)
  total_chars <- total_chars + estimate_orbital_size(model_fit$fit, ...)

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

# Neural network methods (torch/brulee feed-forward networks) ---------------

# Each neuron's expression is structurally a linear predictor over its
# layer's inputs (`estimate_linear_chars()` already models exactly that
# shape), then wrapped in its activation function. relu/sigmoid/tanh/linear
# wrap the linear predictor's text once; leaky_relu/elu/gelu each repeat it
# three times (see `nn_activation_expr()`), so those get a multiplier rather
# than just a fixed additive overhead.
nn_activation_multiplier <- function(activation) {
  if (activation %in% c("leaky_relu", "elu", "gelu")) 3L else 1L
}

nn_activation_overhead <- function(activation) {
  switch(
    activation,
    relu = 10L,
    sigmoid = 22L,
    tanh = 6L,
    gelu = 70L,
    leaky_relu = 45L,
    elu = 45L,
    0L
  )
}

# One layer's total expression character count across all its neurons.
estimate_nn_layer_chars <- function(n_in, n_out, avg_input_len, activation) {
  lin_chars <- estimate_linear_chars(n_in + 1, avg_input_len)
  neuron_chars <- lin_chars *
    nn_activation_multiplier(activation) +
    nn_activation_overhead(activation)
  as.integer(n_out * neuron_chars)
}

# The generated column name length for layer `i`'s neurons, matching
# `nn_layer_exprs()`'s own `<prefix>_<zero-padded index>` naming exactly, so
# a later layer's `avg_input_len` reflects what it actually references.
nn_layer_name_len <- function(i, n_out) {
  prefix <- sprintf("orbital_nn_L%d", i)
  width <- nchar(as.character(n_out))
  nchar(prefix) + 1L + width
}

# Base overhead for the final layer's output routing (`nn_output_eqs()`):
# small and roughly constant regardless of network shape, since it only adds
# a handful of expressions on top of the last layer's raw neurons (a sigmoid
# wrap, a softmax normalization, or a direct pass-through).
estimate_nn_output_chars <- function() 50L

# Walks `layers` (as produced by `nn_sequential_layers()`) the same way
# `nn_forward_eqs()` does, without materializing any actual expression text.
estimate_nn_sequential_chars <- function(layers, input_names) {
  avg_len <- mean(nchar(input_names))
  total_chars <- estimate_nn_output_chars()

  for (i in seq_along(layers)) {
    n_in <- ncol(layers[[i]]$weight)
    n_out <- nrow(layers[[i]]$weight)
    is_last <- i == length(layers)
    activation <- if (is_last) "linear" else layers[[i]]$activation

    total_chars <- total_chars +
      estimate_nn_layer_chars(n_in, n_out, avg_len, activation)
    avg_len <- nn_layer_name_len(i, n_out)
  }

  as.integer(total_chars)
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.nn_sequential <- function(x, ..., input_names) {
  if (missing(input_names)) {
    cli::cli_abort(
      "{.arg input_names} is required for bare {.cls nn_sequential} models."
    )
  }

  layers <- nn_sequential_layers(x$children)

  if (length(layers) == 0) {
    cli::cli_abort("{.arg x} contains no {.cls nn_linear} layers.")
  }

  nn_check_input_names(input_names, ncol(layers[[1]]$weight))

  estimate_nn_sequential_chars(layers, input_names)
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.brulee_mlp <- function(x, ...) {
  rlang::check_installed("brulee")

  module <- brulee_revive_mlp(x)
  layers <- nn_sequential_layers(module$model$children)

  estimate_nn_sequential_chars(layers, x$dims$features)
}

#' @rdname estimate_orbital_size
#' @export
estimate_orbital_size.keras.src.models.sequential.Sequential <- function(
  x,
  ...,
  input_names
) {
  if (missing(input_names)) {
    cli::cli_abort(
      "{.arg input_names} is required for bare keras3 {.cls Sequential}
       models."
    )
  }

  layers <- keras_sequential_layers(x$layers)

  if (length(layers) == 0) {
    cli::cli_abort("{.arg x} contains no {.cls Dense} layers.")
  }

  nn_check_input_names(input_names, ncol(layers[[1]]$weight))

  estimate_nn_sequential_chars(layers, input_names)
}

# Step estimation generic and methods ----------------------------------------

# Internal generic for estimating step character counts
estimate_step_chars <- function(x, ...) {
  UseMethod("estimate_step_chars")
}

# Default: estimate based on number of columns affected
# Most steps produce ~40 chars per column as a rough baseline
#' @exportS3Method
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
#' @exportS3Method
estimate_adj_chars.default <- function(x, ...) {
  80L
}
