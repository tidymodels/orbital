#' Use weasel in a mutate way
#' 
#' @param .data A data frame that can be used with mutate.
#' @param x A weasel object.
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
#' weasel_obj <- weasel(wf_fit)
#' 
#' mtcars %>%
#'   weasel_mutate(weasel_obj)
#' 
#' mtcars %>%
#'   weasel_mutate(weasel_obj, only_pred = TRUE)
#' @export
weasel_mutate <- function(.data, x, only_pred = FALSE) {
  res <- dplyr::mutate(.data, !!!weasel_inline(x))

  if (only_pred) {
    pred_name <- names(x)[length(x)]
    res <- dplyr::select(res, dplyr::any_of(pred_name))
  }

  res
}
