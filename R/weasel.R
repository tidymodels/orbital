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
weasel.workflow <- function(x, ...) {
  model_fit <- workflows::extract_fit_parsnip(x)
  recipe_fit <- workflows::extract_recipe(x)

  out <- weasel(model_fit)
  out <- weasel(recipe_fit, out)
  new_weasel_class(out)
}

#' @export
weasel.model_fit <- function(x, ...) {
  deparse1(tidypredict::tidypredict_fit(x))
}

#' @export
weasel.recipe <- function(x, eqs, ...) {
  all_vars <- all.vars(rlang::parse_expr(eqs))

  n_steps <- length(x$steps)

  out <- c(.pred = eqs)
  for (i in rev(seq_len(n_steps))) {
    res <- weasel(x$steps[[i]], all_vars)

    out <- c(res, out)

    if (!is.null(res)) {
      new_vars <- rlang::parse_exprs(res)
      new_vars <- lapply(new_vars, all.vars)
      new_vars <- unlist(new_vars)
      new_vars <- unique(new_vars)
      all_vars <- unique(c(all_vars, new_vars))
    }
  }
  out
}

#' @export
weasel.step_pca <- function(x, all_vars, ...) {
  rot <- x$res$rotation
  colnames(rot) <- recipes::names0(ncol(rot), x$prefix)

  used_vars <- colnames(rot) %in% all_vars

  rot <- rot[, used_vars]

  row_nms <- rownames(rot)

  out <- character(length(all_vars))
  for (i in seq_along(all_vars)) {
    out[i] <- paste(row_nms, "*", rot[, i], collapse = " + ")
  }

  names(out) <- all_vars
  out
}

#' @export
weasel.step_normalize <- function(x, all_vars, ...) {
  means <- x$means
  sds <- x$sds

  used_vars <- names(means) %in% all_vars
  means <- means[used_vars]
  sds <- sds[used_vars]

  out <- paste0("(", names(means), " - ", means ,") / ", sds)
  names(out) <- names(means)
  out
}

#' @export
weasel.step_nzv <- function(x, all_vars, ...) {
  NULL
}

#' @export
weasel.step_corr <- function(x, all_vars, ...) {
  NULL
}

new_weasel_class <- function(x) {
  class(x) <- "weasel_class"
  x
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
