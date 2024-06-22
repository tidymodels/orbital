#' Use orbital in a mutate way
#'
#' @param .data A data frame that can be used with mutate.
#' @param x A orbital object.
#'
#' @returns A modified data frame.
#'
#' @examplesIf rlang::is_installed("recipes")
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
#' mtcars %>%
#'   orbital_predict(orbital_obj)
#' @export
orbital_predict <- function(.data, x) {
  res <- dplyr::mutate(.data, !!!orbital_inline(x))

  pred_name <- names(x)[length(x)]
  res <- dplyr::select(res, dplyr::any_of(pred_name))

  res
}
