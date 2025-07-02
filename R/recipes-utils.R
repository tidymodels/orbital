lencode_helper <- function(x, all_vars) {
  out <- character()

  x$mapping <- x$mapping[names(x$mapping) %in% all_vars]

  for (i in seq_along(x$mapping)) {
    mapping <- x$mapping[[i]]
    col <- names(x$mapping)[i]

    new_ind <- mapping[["..level"]] == "..new"
    levels <- mapping[["..level"]][!new_ind]
    values <- mapping[["..value"]][!new_ind]
    default <- mapping[["..value"]][new_ind]

    eq <- glue::glue("{col} == \"{levels}\" ~ {values}")
    eq <- c(eq, glue::glue(".default = {default}"))
    eq <- paste(eq, collapse = ", ")
    eq <- glue::glue("dplyr::case_when({eq})")

    names(eq) <- col
    out <- c(out, eq)
  }
  out
}

pca_helper <- function(rot, prefix, all_vars) {
  if (
    is.null(rot) ||
      identical(rot, NA) ||
      identical(rot, matrix(logical(0), nrow = 0L, ncol = 0L))
  ) {
    return(NULL)
  }

  colnames(rot) <- recipes::names0(ncol(rot), prefix)

  used_vars <- pca_naming(colnames(rot), prefix) %in%
    pca_naming(all_vars, prefix)

  rot <- rot[, used_vars]

  row_nms <- rownames(rot)

  out_names <- pca_naming(colnames(rot), prefix)

  out <- list(length(out_names))

  # when should we wrap longer sequences
  n_wrap <- 50

  for (i in seq_len(sum(used_vars))) {
    non_zero <- rot[, i] != 0
    terms <- glue::glue("{row_nms[non_zero]} * {rot[, i][non_zero]}")
    if (length(terms) > n_wrap) {
      split_ind <- rep(
        seq(1, ceiling(length(terms) / n_wrap)),
        each = n_wrap,
        length.out = length(terms)
      )

      terms <- split(terms, split_ind)
      not_first <- seq(2, length(terms))
      terms[not_first] <- lapply(terms[not_first], function(x) {
        c(out_names[[i]], x)
      })

      terms <- lapply(terms, paste, collapse = " + ")
      names(terms) <- rep(out_names[[i]], length(terms))
    } else {
      terms <- paste(terms, collapse = " + ")
      names(terms) <- out_names[[i]]
    }
    out[[i]] <- terms
  }

  unlist(out)
}

pca_naming <- function(x, prefix) {
  gsub(paste0(prefix, "0+"), prefix, x)
}
