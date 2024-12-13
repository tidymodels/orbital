#' Convert to SQL code
#'
#' Returns SQL code that is equivilant to prediction code.
#'
#' @param x An [orbital] object.
#' @param con A connection object.
#'
#' @details
#' This function requires a database connection object, as the resulting code
#' SQL code can differ depending on the type of database.
#'
#' @returns SQL code.
#'
#' @examplesIf rlang::is_installed(c("dbplyr", "recipes", "tidypredict", "workflows"))
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
