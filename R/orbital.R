#' Turn tidymodels workflows into equations
#' 
#' @param x A workflow object.
#' @param ... Not currently used.
#' 
#' @returns A orbital object.
#' 
#' @examplesIf rlang::is_installed(c("recipes", "tidypredict"))
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
#' orbital(wf_fit)
#' 
#' @export
orbital <- function(x, ...) {
  UseMethod("orbital")
}

#' @export
orbital.default <- function(x, ...) {
  cli::cli_abort(
    "Is not implemented for {.obj_type_friendly {x}}."
  )
}

#' @export
print.orbital_class <- function(x, ...) {
  x <- unclass(x)

  eqs <- paste0(names(x), " = ", x)
  
  eqs_lens <- nchar(eqs)
  max_width <- cli::console_width() - 9
  clipped <- eqs_lens > max_width

  eqs[clipped] <- substr(eqs[clipped], 1, max_width)
  eqs[clipped] <- paste(eqs[clipped], "...")

  cli::cli({
    cli::cli_h1("orbital Object")
    cli::cli_ul(eqs)
    cli::cli_rule()
    cli::cli_text("{length(x)} equations in total.")
  })

  invisible(NULL)
}
