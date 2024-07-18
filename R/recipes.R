
#' @export
orbital.recipe <- function(x, eqs = NULL, ...) {
  if (!recipes::fully_trained(x)) {
    cli::cli_abort("recipe must be fully trained.")
  }

  if (is.null(eqs)) {
    terms <- x$term_info
    all_vars <- terms$variable[terms$role == "predictor"]
  } else {
    all_vars <- all.vars(rlang::parse_expr(eqs))
  }

  n_steps <- length(x$steps)

  out <- c(.pred = unname(eqs))
  for (step in rev(x$steps)) {
    res <- tryCatch(
      orbital(step, all_vars),
      error = function(cnd) {
        if (grepl("not implemented", cnd$message)) {
          cls <- class(step)
          cls <- setdiff(cls, "step")
  
          cli::cli_abort(
            "The recipe step {.fun {cls}} is not supported.",
            call = rlang::call2("orbital")
          )
        }
        stop(cnd)
      }
    )

    out <- c(res, out)

    if (!is.null(res)) {
      new_vars <- rlang::parse_exprs(res)
      new_vars <- lapply(new_vars, all.vars)
      new_vars <- unlist(new_vars)
      new_vars <- unique(new_vars)
      all_vars <- unique(c(all_vars, new_vars))
    }
  }

  if (is.null(out)) {
    out <- character()
  }

  new_orbital_class(out)
}
