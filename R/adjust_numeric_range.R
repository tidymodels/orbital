#' @export
orbital.numeric_range <- function(x, tailor, ...) {
  lower <- x$arguments$lower_limit
  upper <- x$arguments$upper_limit

  estimate <- tailor$columns$estimate

  if (!is.finite(lower) && !is.finite(upper)) {
    return(NULL)
  }

  out <- "dplyr::case_when("

  if (is.finite(lower)) {
    out <- paste0(out, "{estimate} < {lower} ~ {lower},")
  }
  if (is.finite(upper)) {
    out <- paste0(out, "{estimate} > {upper} ~ {upper},")
  }

  out <- paste0(out, ".default = {estimate})")
  out <- glue::glue(out)
  names(out) <- estimate
  out
}
