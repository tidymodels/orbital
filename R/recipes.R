
#' @export
orbital.recipe <- function(x, eqs = NULL, ...) {
  if (!recipes::fully_trained(x)) {
    cli::cli_abort("recipe must be fully trained.")
  }

  if (is.null(eqs)) {
    ptype <- recipes::recipes_ptype(x, stage = "bake")
    if (is.null(ptype)) {
      cli::cli_abort("recipe must be created using version 1.1.0 or later.")
    }
    all_vars <- names(ptype)
  } else {
    all_vars <- all.vars(rlang::parse_expr(eqs))
  }

  n_steps <- length(x$steps)

  out <- c(.pred = unname(eqs))
  for (i in rev(seq_len(n_steps))) {
    res <- tryCatch(
      orbital(x$steps[[i]], all_vars),
      error = function(cnd) {
        if (grepl("not implemented", cnd$message)) {
          cls <- class(x$steps[[i]])
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

  new_orbital_class(out)
}
