
#' @export
weasel.recipe <- function(x, eqs = NULL, ...) {
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

  new_weasel_class(out)
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
