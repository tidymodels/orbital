
#' @export
orbital.last_fit <- function(x, ...) {
  x <- hardhat::extract_workflow(x)
  orbital(x)
}