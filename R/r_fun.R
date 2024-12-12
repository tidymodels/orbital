#' Turn orbital object into a R function
#'
#' Returns a R file that contains a function that output predictions when
#' applied to data frames.
#'
#' @param x An [orbital] object.
#' @param name Name of created function. Defaults to `"orbital_predict"``.
#' @param file A file name.
#'
#' @details
#' The generated function is only expected to work on data frame objects. The
#' generated function doesn't require the orbital package to be loaded.
#' Depending on what models and steps are used, other packages such as dplyr
#' will need to be loaded as well.
#'
#' @returns Nothing.
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
#' file_name <- tempfile()
#'
#' orbital_r_fun(orbital_obj, file = file_name)
#'
#' readLines(file_name)
#' @export
orbital_r_fun <- function(x, name = "orbital_predict", file) {
	fun <- c(
		paste(name, "<- function(x) {"),
		"with(x, {",
		paste("  ", names(x), "=", x),
		"  .pred",
		"  })",
		"}"
	)

	writeLines(fun, con = file)
}
