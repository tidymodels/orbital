#' Turn tidymodels workflows into equations
#' 
#' @param x A workflow object.
#' @param ... Not currently used.
#' 
#' @returns A weasel object.
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
#' weasel(wf_fit)
#' 
#' @export
weasel <- function(x, ...) {
  UseMethod("weasel")
}

#' @export
weasel.default <- function(x, ...) {
  cli::cli_abort(
    "Is not implemented for {.obj_type_friendly {x}}."
  )
}

#' @export
print.weasel_class <- function(x, ...) {
  x <- unclass(x)

  eqs <- paste0(names(x), " = ", x)
  eqs <- substr(eqs, 1, cli::console_width() - 9)
  eqs <- paste(eqs, "...")

  cli::cli({
    cli::cli_h1("Weasel Object")
    cli::cli_ul(eqs)
    cli::cli_rule()
    cli::cli_text("{length(x)} equations in total.")
  })

  invisible(NULL)
}
