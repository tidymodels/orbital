#' @export
orbital.step_discretize <- function(x, all_vars, ...) {
  out <- character()

  for (i in seq_along(x$objects)) {
    object <- x$objects[[i]]
    if (object$bins == 0) {
      next
    }

    col <- names(x$objects)[i]

    eq <- character()

    if (object$keep_na) {
      eq <- c(eq, paste0("is.na(", col, ")"))
    }

    eq <- c(eq, paste0(col, " < ", object$breaks[2]))
    if (object$bins > 2) {
      low <- seq(2, object$bins - 1)
      high <- low + 1

      eq <- c(eq, 
        paste0(object$breaks[low], " < ", col, " & ",
               col, " <= ", object$breaks[high])
      )
    }

    eq <- c(eq, paste0(utils::tail(object$breaks, 2)[1], " <= ", col))
    
    eq <- paste0(eq, " ~ \"", paste0(object$prefix, object$labels), "\"")

    eq <- paste0("dplyr::case_when(", paste0(eq, collapse = ", "), ")")
    names(eq) <- col
    out <- c(out, eq)
  }

  out
}