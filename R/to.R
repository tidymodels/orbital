#' Turn weasel object into a R function
#' 
#' @param x A weasel object.
#' @param name Name of created function. Defaults to `"weasel_predict"``.
#' @param file A file name.
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
#' weasel_obj <- weasel(wf_fit)
#' 
#' file_name <- tempfile()
#' 
#' to_r_fun(weasel_obj, file = file_name)
#' 
#' readLines(file_name)
#' @export
to_r_fun <- function(x, name = "weasel_predict", file) {
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

