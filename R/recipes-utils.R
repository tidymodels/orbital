lencode_helper <- function(x) {
  out <- character()

  for (i in seq_along(x$mapping)) {
    mapping <- x$mapping[[i]]
    col <- names(x$mapping)[i]

    new_ind <- mapping[["..level"]] == "..new"
    levels <- mapping[["..level"]][!new_ind]
    values <- mapping[["..value"]][!new_ind]
    default <- mapping[["..value"]][new_ind]

    eq <- paste0(col, " == \"", levels, "\" ~ ", values)
    eq <- c(eq, paste0(".default = ", default))

    eq <- paste0("dplyr::case_when(", paste0(eq, collapse = ", "), ")")
    names(eq) <- col
    out <- c(out, eq)
  }
  out
}

pca_helper <- function(rot, prefix, all_vars) {
  colnames(rot) <- recipes::names0(ncol(rot), prefix)

  used_vars <- pca_naming(colnames(rot), prefix) %in% 
    pca_naming(all_vars, prefix)

  rot <- rot[, used_vars]

  row_nms <- rownames(rot)

  out <- character(length(all_vars))
  for (i in seq_along(all_vars)) {
    out[i] <- paste(row_nms, "*", rot[, i], collapse = " + ")
  }

  names(out) <- all_vars
  out
}

pca_naming <- function(x, prefix) {
  gsub(paste0(prefix, "0"), prefix, x)
}