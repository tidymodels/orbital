#' @export
weasel.workflow <- function(x, ...) {
  if (!workflows::is_trained_workflow(x)) {
    cli::cli_abort("{.arg x} must be a fully trained {.cls workflow}.")
  }
  
  model_fit <- workflows::extract_fit_parsnip(x)
  recipe_fit <- workflows::extract_recipe(x)

  out <- weasel(model_fit)
  out <- weasel(recipe_fit, out)
  new_weasel_class(out)
}