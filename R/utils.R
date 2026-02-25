# Format numeric values with full precision for SQL/expression serialization
# Uses digits17 control to ensure IEEE 754 round-trip accuracy
format_numeric <- function(x) {
  vapply(x, function(e) deparse1(e, control = "digits17"), character(1))
}

# Build linear predictor expression with full numeric precision
# Replacement for tidypredict::.build_linear_pred() that uses digits17
build_linear_pred <- function(coef_names, coef_values) {
  terms <- character(0)
  for (i in seq_along(coef_names)) {
    if (coef_values[i] == 0) {
      next
    }
    if (coef_names[i] == "(Intercept)") {
      terms <- c(terms, format_numeric(coef_values[i]))
    } else {
      var_name <- paste0("`", coef_names[i], "`")
      terms <- c(
        terms,
        paste0("(", var_name, " * ", format_numeric(coef_values[i]), ")")
      )
    }
  }
  if (length(terms) == 0) {
    return("0")
  }
  paste(terms, collapse = " + ")
}

namespace_case_when <- function(x) {
  names <- names(x)
  x <- gsub("dplyr::case_when", "case_when", x)
  x <- gsub("case_when", "dplyr::case_when", x)
  names(x) <- names
  x
}
