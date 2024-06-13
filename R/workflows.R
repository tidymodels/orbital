#' @export
weasel.workflow <- function(x, ...) {
  model_fit <- workflows::extract_fit_parsnip(x)
  recipe_fit <- workflows::extract_recipe(x)

  out <- weasel(model_fit)
  out <- weasel(recipe_fit, out)
  new_weasel_class(out)
}