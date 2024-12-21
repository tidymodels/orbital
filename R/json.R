#' Save orbital object as json file
#'
#' Saving an orbital object to disk in a human and machine readable way.
#'
#' @param x An [orbital] object.
#' @param path file on disk.
#'
#' @details
#' The structure of the resulting JSON file allows for easy reading, both by
#' orbital itself with [orbital_json_read()], but potentially by other packages
#' and langauges. The file is versioned by the `version` field to allow for
#' changes why being backwards combatible with older file versions.
#'
#' @returns Nothing.
#'
#' @seealso [orbital_json_read()]
#'
#' @examplesIf rlang::is_installed(c("jsonlite", "recipes", "tidypredict", "workflows"))
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

	res <- list(
		actions = actions,
		pred_names = attr(x, "pred_names"),
		version = 2
	)

	res <- jsonlite::toJSON(res, pretty = TRUE, auto_unbox = TRUE)

	writeLines(res, path)
}

#' Read orbital json file
#'
#' Reading an orbital object from disk
#'
#' @param path file on disk.
#'
#' @details
#' This function is aware of the `version` field of the orbital object, and will
#' read it in correctly, according to its specification.
#'
#' @returns An [orbital] object.
#'
#' @seealso [orbital_json_write()]
#'
#' @examplesIf rlang::is_installed(c("jsonlite", "recipes", "tidypredict", "workflows"))
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
	rlang::check_installed("jsonlite")

	json <- jsonlite::read_json(path)

	version <- json$version

	if (version == 1) {
		res <- unlist(json$actions)
		attr(res, "pred_names") <- utils::tail(names(res), 1)
	} else if (version == 2) {
		res <- unlist(json$actions)
		attr(res, "pred_names") <- json$pred_names
	}

	new_orbital_class(res)
}
