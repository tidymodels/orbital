#' Turn tidymodels objects into orbital objects
#' 
#' Fitted workflows, parsnip objects, and recipes objects can be turned into an
#' orbital object that contain all the information needed to perform 
#' predictions.
#' 
#' @param x A fitted workflow, parsnip, or recipes object.
#' @param ... Not currently used.
#' 
#' @returns A orbital object.
#' 
#' @details
#' An orbital object contains all the information that is needed to perform
#' predictions. This makes the objects substantially smaller than the original 
#' objects. The main downside with this object is that all the input checking
#' has been removed, and it is thus up to the user to make sure the data is 
#' correct.
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
#' orbital(wf_fit)
#' 
#' # Also works on parsnip object by itself
#' fit(lm_spec, mpg ~ disp, data = mtcars) %>%
#'   orbital()
#' 
#' # And prepped recipes
#' prep(rec_spec) %>%
#'   orbital()
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

new_orbital_class <- function(x) {
  class(x) <- "orbital_class"
  x
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
