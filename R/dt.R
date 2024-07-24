#' Convert to data.table code
#' 
#' 
#' 
#' @param x A orbital object.
#' 
#' @returns data.table code.
#' 
#' @examplesIf rlang::is_installed(c("dbplyr", "dtplyr", "recipes", "tidypredict", "workflows"))
#' 
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
#' orbital_dt(orbital_obj)
#' @export
orbital_dt <- function(x) {
  rlang::check_installed("dtplyr")

  dt <- dtplyr::lazy_dt(data.frame())

  res <- dplyr::mutate(dt, !!!orbital_inline(x))

  dplyr::show_query(res)
}
