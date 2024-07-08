#' Prediction using orbital objects
#'
#' @param object A orbital object.
#' @param new_data A data frame to predict with.
#' @param ... Not currently used.
#'
#' @returns A modified data frame.
#'
#' @examplesIf rlang::is_installed(c("recipes", "tidypredict", "workflows"))
#' library(workflows)
#' library(recipes)
#' library(parsnip)
#'
#' rec_spec <- recipe(mpg ~ ., data = mtcars) %>%
#'   step_normalize(all_numeric_predictors())
#'
#' lm_spec <- linear_reg()
#'
#' wf_spec <- workflow(rec_spec, lm_spec)
#'
#' wf_fit <- fit(wf_spec, mtcars)
#'
#' orbital_obj <- orbital(wf_fit)
#'
#' predict(orbital_obj, mtcars)
#' @export
predict.orbital_class <- function(object, new_data, ...) {
  rlang::check_dots_empty()
  res <- dplyr::mutate(new_data, !!!orbital_inline(object))

  pred_name <- names(object)[length(object)]
  res <- dplyr::select(res, dplyr::any_of(pred_name))

  res
}
