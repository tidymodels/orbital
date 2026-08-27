# Write a double as the shortest decimal that R reads back unchanged.
#
# `%.17g` is correctly rounded, but R's decimal parser is not: it accumulates
# the mantissa as a double, so a 17-digit literal can land one ulp away from
# the value that produced it. That is invisible in a linear predictor and
# decisive in a tree, whose cutpoints sit on values realized by training rows,
# where one ulp flips `<=` and sends a row down the other branch.
#
# Fewer digits means less accumulated error, so trying shortest-first both
# keeps the equations readable and round-trips more often than `%.17g` does.
# Some doubles no decimal literal reaches; those fall back to `%.17g`, which is
# at least the closest decimal to the value.
format_double <- function(x) {
  if (!is.finite(x)) {
    return(deparse1(x, control = "digits17"))
  }

  candidates <- sprintf("%.*g", 1:17, x)
  candidates <- candidates[as.numeric(candidates) == x]

  if (length(candidates) == 0) {
    return(sprintf("%.17g", x))
  }

  # Shortest by width rather than by digits, since `%g` switches to scientific
  # notation on its own: `10` asked for one digit comes back as `1e+01`.
  candidates[which.min(nchar(candidates))]
}

# Format numeric values with full precision for SQL/expression serialization
format_numeric <- function(x) {
  vapply(x, format_double, character(1))
}

# Everything `format_double()` can produce, and nothing that needs quoting for
# any other reason. Numeric literals are re-quoted on their way through
# `deparse()` because they are carried as symbols; this takes the quotes back
# off again.
numeric_literal_rx <- "`(-?[0-9]+([.][0-9]+)?(e[+-]?[0-9]+)?)`"

# Deparse an expression, writing every double the way `format_double()` does.
#
# `deparse()` has no hook for formatting literals, so each one is swapped for a
# symbol carrying the text to emit and unquoted again afterwards.
deparse_exact <- function(x) {
  out <- deparse1(exact_literals(x), control = "digits17")
  gsub(numeric_literal_rx, "\\1", out)
}

exact_literals <- function(x) {
  if (is.double(x) && length(x) == 1 && !is.na(x)) {
    return(as.name(format_double(x)))
  }

  if (!is.call(x)) {
    return(x)
  }

  for (i in seq_along(x)) {
    # A call can hold empty arguments, which cannot be fetched or reassigned.
    if (!identical(x[[i]], quote(expr = ))) {
      x[[i]] <- exact_literals(x[[i]])
    }
  }

  x
}

# Build linear predictor expression with full numeric precision
# Replacement for tidypredict::.build_linear_pred() that keeps full precision
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

# Deparse a list of expressions, as returned by tidypredict's extractor
# generics, into the character equations orbital passes around. Names are kept.
deparse_eqs <- function(x) {
  vapply(x, deparse_exact, character(1))
}

namespace_case_when <- function(x) {
  names <- names(x)
  x <- gsub("dplyr::case_when", "case_when", x)
  x <- gsub("case_when", "dplyr::case_when", x)
  names(x) <- names
  x
}
