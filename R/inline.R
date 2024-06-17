#' Use weasel object splicing function
#' 
#' @param x A weasel object.
#' 
#' @details
#' 
#' This function is mostly going to be used for 
#' [Dots Injection](https://rlang.r-lib.org/reference/topic-inject.html#dots-injection).
#' See examples for use cases.
#' 
#' @returns a list of quosures.
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
#' library(dplyr)
#' 
#' mtcars %>%
#'   mutate(!!!weasel_inline(weasel_obj))
#' @export
weasel_inline <- function(x) {
  rlang::parse_quos(x, env = rlang::global_env())
}