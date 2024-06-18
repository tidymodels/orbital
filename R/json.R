#' Save as json file
#' 
#' @param x A orbital object.
#' @param path file on disk.
#' 
#' @returns nothing.
#' 
#' @seealso [orbital_json_read()]
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
#' orbital_obj <- orbital(wf_fit)
#' 
#' tmp_file <- tempfile()
#' 
#' orbital_json_write(orbital_obj, tmp_file)
#' 
#' readLines(tmp_file)
#' @export
orbital_json_write <- function(x, path) {
  actions <- as.list(unclass(x))

  res <- list(actions = actions, version = 1)
  res <- jsonlite::toJSON(res, pretty = TRUE, auto_unbox = TRUE)

  writeLines(res, path)
}

#' Read orbital json file
#' 
#' @param path file on disk.
#' 
#' @returns A orbital object
#' 
#' @seealso [orbital_json_write()]
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
#' orbital_obj <- orbital(wf_fit)
#' 
#' tmp_file <- tempfile()
#' 
#' orbital_json_write(orbital_obj, tmp_file)
#' 
#' orbital_json_read(tmp_file)
#' @export
orbital_json_read <- function(path) {
  res <- jsonlite::read_json(path)

  res <- unlist(res$actions)
  
  new_orbital_class(res)
}
