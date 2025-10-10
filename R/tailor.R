#' @export
orbital.tailor <- function(x, ...) {
  out <- character()

  for (adj in x$adjustments) {
    new <- orbital(adj, tailor = x, ...)
    out <- c(out, new)
  }

  new_orbital_class(out)
}
