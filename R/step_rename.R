#' @export
orbital.step_rename <- function(x, all_vars, ...) {
  inputs <- lapply(x$inputs, rlang::as_label)

  used_vars <- names(inputs) %in% all_vars
  inputs <- inputs[used_vars]

  out <- unlist(inputs)
  out
}