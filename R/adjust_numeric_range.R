#' @export
orbital.numeric_range <- function(x, tailor, ...) {
  lower <- x$arguments$lower_limit
  upper <- x$arguments$upper_limit

  estimate <- tailor$columns$estimate

  if (!is.finite(lower) && !is.finite(upper)) {
    return(NULL)
  }

  lower_fmt <- format_numeric(lower)
  upper_fmt <- format_numeric(upper)

  out <- "dplyr::case_when("

  if (is.finite(lower)) {
    out <- paste0(out, "{estimate} < {lower_fmt} ~ {lower_fmt},")
  }
  if (is.finite(upper)) {
    out <- paste0(out, "{estimate} > {upper_fmt} ~ {upper_fmt},")
  }

  out <- paste0(out, "TRUE ~ {estimate})")
  out <- glue::glue(out)
  names(out) <- estimate
  out
}
