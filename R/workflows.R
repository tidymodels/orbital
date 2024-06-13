#' @export
weasel.workflow <- function(x, ...) {
  if (!workflows::is_trained_workflow(x)) {
    cli::cli_abort("{.arg x} must be a fully trained {.cls workflow}.")
  }

  model_fit <- workflows::extract_fit_parsnip(x)
  out <- weasel(model_fit)
  
  preprocessor <- workflows::extract_preprocessor(x)

  if (inherits(preprocessor, "recipe")) {
    recipe_fit <- workflows::extract_recipe(x)

    out <- weasel(recipe_fit, out)
  }

  new_weasel_class(out)
}