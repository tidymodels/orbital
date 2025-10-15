#' @export
orbital.workflow <- function(x, ..., prefix = ".pred", type = NULL) {
  if (!workflows::is_trained_workflow(x)) {
    cli::cli_abort("{.arg x} must be a fully trained {.cls workflow}.")
  }

  out <- character()
  if ("tailor" %in% names(x$post$actions)) {
    tailor_fit <- workflows::extract_tailor(x)
    post <- orbital(tailor_fit, prefix = prefix, type = type)
    out <- post
  }

  model_fit <- workflows::extract_fit_parsnip(x)
  mod <- orbital(model_fit, prefix = prefix, type = type)
  mod_atr <- attributes(mod)
  mod_atr$names <- c(mod_atr$names, names(out))
  mod_cls <- class(mod)
  out <- c(mod, out)
  attributes(out) <- mod_atr
  class(out) <- mod_cls

  preprocessor <- workflows::extract_preprocessor(x)

  if (inherits(preprocessor, "recipe")) {
    recipe_fit <- workflows::extract_recipe(x)

    pred_names <- attr(out, "pred_names")
    out <- orbital(recipe_fit, out, prefix = prefix)
    attr(out, "pred_names") <- pred_names
  }

  out <- namespace_case_when(out)

  new_orbital_class(out)
}
