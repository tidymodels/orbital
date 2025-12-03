#' Turn tidymodels objects into orbital objects
#'
#' Fitted workflows, parsnip objects, and recipes objects can be turned into an
#' orbital object that contain all the information needed to perform
#' predictions.
#'
#' @param x A fitted workflow, parsnip, or recipes object.
#' @param ... Not currently used.
#' @param prefix A single string, specifies the prediction naming scheme.
#'   If `x` produces a prediction, tidymodels standards dictate that the
#'   predictions will start with `.pred`. This is not a valid name for
#'   some data bases.
#' @param type A vector of strings, specifies the prediction type. Regression
#'   models allow for `"numeric"` and classification models allow for `"class"`
#'   and `"prob"`. Multiple values are allowed to produce hard and soft
#'   predictions for classification models. Defaults to `NULL` which defaults to
#'   `"numeric"` for regression models and `"class"` for classification models.
#'
#' @returns An [orbital] object.
#'
#' @details
#' An orbital object contains all the information that is needed to perform
#' predictions. This makes the objects substantially smaller than the original
#' objects. The main downside with this object is that all the input checking
#' has been removed, and it is thus up to the user to make sure the data is
#' correct.
#'
#' The printing of orbital objects reduce the number of significant digits for
#' easy viewing, the can be changes by using the `digits` argument of `print()`
#' like so `print(orbital_object, digits = 10)`. The printing likewise truncates
#' each equation to fit on one line. This can be turned off using the `truncate`
#' argument like so `print(orbital_object, truncate = FALSE)`.
#'
#' Full list of supported models and recipes steps can be found here:
#' `vignette("supported-models")`.
#'
#' These objects will not be useful by themselves. They can be used to
#' [predict()][predict.orbital_class] with, or to generate code using functions
#' such as [orbital_sql()] or [orbital_dt()].
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
#' orbital(wf_fit)
#'
#' # Also works on parsnip object by itself
#' fit(lm_spec, mpg ~ disp, data = mtcars) |>
#'   orbital()
#'
#' # And prepped recipes
#' prep(rec_spec) |>
#'   orbital()
#'
#' @export
orbital <- function(x, ..., prefix = ".pred", type = NULL) {
  UseMethod("orbital")
}

#' @export
orbital.default <- function(x, ...) {
  cli::cli_abort(
    "Is not implemented for {.obj_type_friendly {x}}."
  )
}

new_orbital_class <- function(x) {
  class(x) <- "orbital_class"
  x
}

#' @export
print.orbital_class <- function(x, ..., digits = 7, truncate = TRUE) {
  x <- unclass(x)
  x <- pretty_print(x, digits)

  eqs <- glue::glue("{names(x)} = {x}")

  if (truncate) {
    eqs_lens <- nchar(eqs)
    max_width <- cli::console_width() - 9
    clipped <- eqs_lens > max_width

    eqs[clipped] <- substr(eqs[clipped], 1, max_width)
    eqs[clipped] <- paste(eqs[clipped], "...")
  }

  cli::cli({
    cli::cli_h1("orbital Object")
    cli::cli_ul(eqs)
    cli::cli_rule()
    cli::cli_text("{length(x)} equations in total.")
  })

  invisible(NULL)
}

pretty_print <- function(x, digits = 7) {
  old_values <- regmatches(x, gregexpr("[0-9]+\\.?[0-9]+", x))
  new_values <- lapply(old_values, function(x) signif(as.numeric(x), digits))

  old_values <- unlist(old_values, use.names = FALSE)
  new_values <- unlist(new_values, use.names = FALSE)

  for (i in seq_along(old_values)) {
    x <- sub(old_values[i], new_values[i], x)
  }

  x
}
