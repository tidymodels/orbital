#' Save as json file
#' 
#' @param x A weasel object.
#' @param path file on disk.
#' 
#' @returns nothing.
#' 
#' @seealso [weasel_json_read()]
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
#' tmp_file <- tempfile()
#' 
#' weasel_json_write(weasel_obj, tmp_file)
#' 
#' readLines(tmp_file)
#' @export
weasel_json_write <- function(x, path) {
  actions <- as.list(unclass(x))

  res <- list(actions = actions, version = 1)
  res <- jsonlite::toJSON(res, pretty = TRUE, auto_unbox = TRUE)

  writeLines(res, path)
}

#' Read weasel json file
#' 
#' @param path file on disk.
#' 
#' @returns A weasel object
#' 
#' @seealso [weasel_json_write()]
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
#' tmp_file <- tempfile()
#' 
#' weasel_json_write(weasel_obj, tmp_file)
#' 
#' weasel_json_read(tmp_file)
#' @export
weasel_json_read <- function(path) {
  res <- jsonlite::read_json(path)

  res <- unlist(res$actions)
  
  new_weasel_class(res)
}
