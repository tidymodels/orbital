#' @export
orbital.glmnet <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL,
  penalty = NULL
) {
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (is.null(penalty)) {
    # Check if model has single lambda
    if (length(x$lambda) != 1) {
      cli::cli_abort(
        c(
          "glmnet model has multiple penalty values.",
          "i" = "Specify a single {.arg penalty} value or fit with a single lambda."
        )
      )
    }
    penalty <- x$lambda
  }

  if (mode == "classification") {
    if (inherits(x, "multnet")) {
      # Multiclass classification
      class_eqs <- tidypredict::.extract_glmnet_multiclass(x, penalty = penalty)
      # Reorder to match lvl order
      class_eqs <- class_eqs[lvl]
      res <- multiclass_from_logits(unlist(class_eqs), type, lvl)
    } else {
      # Binary classification
      eq <- glmnet_logistic_expr(x, penalty)
      res <- binary_from_prob(eq, type, lvl)
    }
  } else if (mode == "regression") {
    eq <- glmnet_linear_expr(x, penalty)
    res <- eq
  }
  res
}

glmnet_logistic_expr <- function(x, penalty) {
  linear_pred <- glmnet_linear_expr(x, penalty)
  glue::glue("1 / (1 + exp(-({linear_pred})))")
}

glmnet_linear_expr <- function(x, penalty) {
  coefs <- stats::coef(x, s = penalty)
  coef_names <- rownames(coefs)
  coef_values <- as.numeric(coefs)
  tidypredict::.build_linear_pred(coef_names, coef_values)
}
