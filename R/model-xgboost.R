#' @export
orbital.xgb.Booster <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,

  lvl = NULL,
  separate_trees = FALSE,
  prefix = ".pred"
) {
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (mode == "classification") {
    objective <- x$params$objective %||% attr(x, "params")$objective
    objective <- rlang::arg_match0(
      objective,
      c("multi:softprob", "binary:logistic")
    )

    extractor <- switch(
      objective,
      "multi:softprob" = xgboost_multisoft,
      "binary:logistic" = xgboost_logistic
    )

    res <- extractor(x, type, lvl, separate_trees, prefix)
  } else if (mode == "regression") {
    res <- xgboost_regression(x, separate_trees, prefix)
  }
  res
}

xgboost_regression <- function(x, separate_trees, prefix) {
  if (!separate_trees) {
    return(tidypredict::tidypredict_fit(x))
  }

  # Extract individual trees
  trees <- tidypredict::.extract_xgb_trees(x)

  # Get base_score from model
  json_params <- get_xgb_json_params(x)
  base_score <- json_params$base_score %||% 0.5

  # Get objective to determine transformation
  params <- attr(x, "param") %||% x$params
  objective <- params$objective

  # Format as separate expressions
  res <- format_separate_trees(trees, prefix)

  # Apply objective-specific transformation to the sum
  sum_name <- prefix
  if (
    objective %in%
      c(
        "reg:squarederror",
        "reg:squaredlogerror",
        "binary:logitraw",
        "reg:pseudohubererror",
        "reg:absoluteerror"
      ) ||
      is.null(objective)
  ) {
    if (base_score != 0) {
      res[[sum_name]] <- paste0(base_score, " + ", res[[sum_name]])
    }
  } else if (objective %in% c("count:poisson", "reg:tweedie", "reg:gamma")) {
    res[[sum_name]] <- paste0(base_score, " * exp(", res[[sum_name]], ")")
  }

  res
}

# Helper to get xgboost JSON params (base_score, weight_drop for DART)
get_xgb_json_params <- function(model) {
  tmp_file <- tempfile(fileext = ".json")
  on.exit(unlink(tmp_file), add = TRUE)
  xgboost::xgb.save(model, tmp_file)

  json <- jsonlite::fromJSON(tmp_file)

  base_score <- json$learner$learner_model_param$base_score
  base_score <- gsub("\\[", "", base_score)
  base_score <- gsub("\\]", "", base_score)
  base_score <- strsplit(base_score, ",")[[1]]
  base_score <- as.numeric(base_score)

  list(
    base_score = base_score,
    weight_drop = json$learner$gradient_booster$weight_drop
  )
}

xgboost_multisoft <- function(x, type, lvl, separate_trees, prefix) {
  trees <- tidypredict::.extract_xgb_trees(x)

  trees_split <- split(
    trees,
    rep(seq_along(lvl), x$niter %||% nrow(attr(x, "evaluation_log")))
  )
  trees_split <- lapply(trees_split, collapse_stumps)

  if (!separate_trees) {
    trees_split <- vapply(
      trees_split,
      function(trees) {
        tree_strs <- vapply(
          trees,
          function(e) deparse1(e, control = "digits17"),
          character(1)
        )
        paste(tree_strs, collapse = " + ")
      },
      character(1)
    )
    return(multiclass_from_logits(trees_split, type, lvl))
  }

  format_multiclass_logits_separate(trees_split, type, lvl, prefix)
}

xgboost_logistic <- function(x, type, lvl, separate_trees, prefix) {
  if (!separate_trees) {
    eq <- tidypredict::tidypredict_fit(x)
    eq <- deparse1(eq)
    return(binary_from_prob_first(eq, type, lvl))
  }

  # separate_trees = TRUE
  trees <- tidypredict::.extract_xgb_trees(x)

  # Get base_score
  json_params <- get_xgb_json_params(x)
  base_score <- json_params$base_score %||% 0.5

  # Format trees separately, using a logit prefix
  logit_prefix <- paste0(prefix, "_logit")
  res <- format_separate_trees(trees, logit_prefix)

  # Apply logistic transformation to the sum
  logit_name <- backtick(logit_prefix)
  prob_eq <- paste0(
    "1 - 1/(1 + exp(",
    logit_name,
    " + log(",
    base_score,
    "/(1 - ",
    base_score,
    "))))"
  )

  res <- binary_from_prob_first_with_eq(res, prob_eq, type, lvl)
  res
}
