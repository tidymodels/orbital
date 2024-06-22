#' Use orbital object splicing function
#' 
#' @param x A orbital object.
#' 
#' @details
#' 
#' This function is mostly going to be used for 
#' [Dots Injection](https://rlang.r-lib.org/reference/topic-inject.html#dots-injection).
#' See examples for use cases.
#' 
#' @returns a list of quosures.
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
#' library(dplyr)
#' 
#' mtcars %>%
#'   mutate(!!!orbital_inline(orbital_obj))
#' @export
orbital_inline <- function(x) {
  rlang::parse_quos(x, env = rlang::global_env())
}