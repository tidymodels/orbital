#' Prediction using orbital objects
#'
#' Running prediction on data frame of remote database table, without needing to
#' load original packages used to fit model.
#' 
#' @param object An [orbital] object.
#' @param new_data A data frame or remote database table.
#' @param ... Not currently used.
#'
#' @details
#' Using this function should give identical results to running `predict()` or
#' `bake()` on the orginal object. 
#' 
#' The prediction done will only return prediction colunms, a opposed to 
#' returning all modified functions as done with [orbital_inline()].
#' 
#' @returns A modified data frame or remote database table.
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
