#' Convert to SQL code
#' 
#' @param x A weasel object.
#' @param con A connection object.
#' 
#' @returns SQL code.
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
#' library(dbplyr)
#' con <- simulate_dbi()
#' 
#' weasel_sql(weasel_obj, con)
#' @export
weasel_sql <- function(x, con) {
  dbplyr::translate_sql(!!!weasel_inline(x), con = con)
}
