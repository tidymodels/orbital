#' @export
orbital.step_rename <- function(x, all_vars, ...) {
  inputs <- lapply(x$inputs, rlang::as_label)

  inputs <- inputs[names(inputs) %in% all_vars]

  out <- unlist(inputs)
  out
}