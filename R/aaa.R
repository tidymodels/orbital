# nocov start

# Imports ----------------------------------------------------------------------

# `%||%` only became a base function in R 4.4.0, and this package supports 4.1.
#' @importFrom rlang %||%
NULL

# Global vars ------------------------------------------------------------------

utils::globalVariables(
  c(
    ":=" # augment.R
  )
)

# nocov end
