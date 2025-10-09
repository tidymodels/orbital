#' @export
orbital.tailor <- function(x, ...) {
  out <- c()

  for (adj in x$adjustments) {
    new <- orbital(adj)
    out <- c(out, new)
  }

  new_orbital_class(out)
}
