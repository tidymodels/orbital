#' Convert to data.table code
#' 
#' @param x A weasel object.
#' 
#' @returns data.table code.
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
#' weasel_dt(weasel_obj)
#' @export
weasel_dt <- function(x) {
  dt <- dtplyr::lazy_dt(data.frame())

  res <- dplyr::mutate(dt, !!!weasel_inline(x))

  dplyr::show_query(res)
}
