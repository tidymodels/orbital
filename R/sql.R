#' Convert to SQL code
#' 
#' @param x A orbital object.
#' @param con A connection object.
#' 
#' @returns SQL code.
#' 
#' @examplesIf rlang::is_installed("dbplyr")
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
#' library(dbplyr)
#' con <- simulate_dbi()
#' 
#' orbital_sql(orbital_obj, con)
#' @export
orbital_sql <- function(x, con) {
  dbplyr::translate_sql(!!!orbital_inline(x), con = con)
}
