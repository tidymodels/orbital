#' Use orbital in a mutate way
#' 
#' @param .data A data frame that can be used with mutate.
#' @param x A orbital object.
#' @param only_pred A logical value to determine if whole data set should be 
#'   returned or just predictions.
#' 
#' @returns A modified data frame.
#' 
#' @examples
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
#'   orbital_mutate(orbital_obj)
#' 
#' mtcars %>%
#'   orbital_mutate(orbital_obj, only_pred = TRUE)
#' @export
orbital_mutate <- function(.data, x, only_pred = FALSE) {
  res <- dplyr::mutate(.data, !!!orbital_inline(x))

  if (only_pred) {
    pred_name <- names(x)[length(x)]
    res <- dplyr::select(res, dplyr::any_of(pred_name))
  }

  res
}
