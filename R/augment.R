#' Augment using orbital objects
#'
#' [augment()] will add column(s) for predictions to the given data.
#'
#' @param x An [orbital] object.
#' @param new_data A data frame or remote database table.
#' @param ... Not currently used.
#'
#' @details
#' This function is a shorthand for the following code
#'
#' ```r
#' dplyr::bind_cols(
#'   predict(orbital_obj, new_data),
#'   new_data
#' )
#' ````
#'
#' Note that [augment()] works better and safer than above as it also works on
#' data set in data bases.
#'
#' This function is confirmed to not work work in spark data bases or arrow
#' tables.
#'
#' @returns A modified data frame or remote database table.
#'
#' @examplesIf rlang::is_installed(c("recipes", "tidypredict", "workflows"))
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
#' augment(orbital_obj, mtcars)
#' @export
augment.orbital_class <- function(x, new_data, ...) {
  index_name <- utils::tail(make.unique(c(colnames(new_data), "..index")), 1)

  preds <- stats::predict(x, new_data)
  preds <- dplyr::mutate(preds, !!index_name := dplyr::row_number())

  new_data <- dplyr::mutate(new_data, !!index_name := dplyr::row_number())

  res <- dplyr::left_join(preds, new_data, by = index_name)
  dplyr::select(res, -dplyr::all_of(index_name))
}
