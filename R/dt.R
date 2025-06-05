#' Convert to data.table code
#'
#' Returns [data.table](https://rdatatable.gitlab.io/data.table/) code that
#' is equivilant to prediction code.
#'
#' @param x An [orbital] object.
#'
#' This function requires [dtplyr](https://dtplyr.tidyverse.org/) to be
#' installed to run. The resulting code will likely need to be adopted to your
#' use-case. Most likely by removing the initial `copy(data-name)` at the start.
#'
#' @returns data.table code.
#'
#' @examplesIf rlang::is_installed(c("dbplyr", "dtplyr", "recipes", "tidypredict", "workflows"))
#'
#' library(workflows)
#' library(recipes)
#' library(parsnip)
#'
#' rec_spec <- recipe(mpg ~ ., data = mtcars) |>
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
