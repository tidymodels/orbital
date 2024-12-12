#' Convert orbital objects to quosures
#'
#' Use orbital object splicing function to apply orbital prediction in a quosure
#' aware function such as [dplyr::mutate()].
#'
#' @param x An [orbital] object.
#'
#' @details
#'
#' This function is mostly going to be used for
#' [Dots Injection](https://rlang.r-lib.org/reference/topic-inject.html#dots-injection).
#' This function is used internally in [predict()][predict.orbital_class], but
#' is also exported for user flexibility. Should be used with `!!!` as seen in
#' the examples.
#'
#' Note should be taken that using this function modifies existing variables and
#' creates new variables, unlike [predict()][predict.orbital_class] which only
#' returns predictions.
#'
#' @returns a list of [quosures][rlang::quos].
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
#' orbital_inline(orbital_obj)
#'
#' library(dplyr)
#'
#' mtcars %>%
#'   mutate(!!!orbital_inline(orbital_obj))
#' @export
orbital_inline <- function(x) {
	rlang::parse_quos(x, env = rlang::global_env())
}
