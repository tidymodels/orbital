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

spline_helper <- function(x, all_vars, spline_fn) {
  results <- x$results

  var_names <- names(results)
  keep_vars <- vapply(
    var_names,
    function(var) {
      n_cols <- results[[var]]$dim[2]
      out_names <- paste0(var, "_", seq_len(n_cols))
      any(out_names %in% all_vars)
    },
    logical(1)
  )

  results <- results[keep_vars]

  if (length(results) == 0) {
    return(NULL)
  }

  out <- character()

  for (var in names(results)) {
    info <- results[[var]]
    n_basis <- info$dim[2]

    out_names <- paste0(var, "_", seq_len(n_basis))
    needed <- out_names %in% all_vars

    if (!any(needed)) {
      next
    }

    knots <- info$knots
    boundary_knots <- info$Boundary.knots
    all_knots <- c(boundary_knots[1], knots, boundary_knots[2])
    n_intervals <- length(all_knots) - 1

    for (basis_idx in which(needed)) {
      out_name <- out_names[basis_idx]
      coefs_list <- list()

      for (interval_idx in seq_len(n_intervals)) {
        x_low <- all_knots[interval_idx]
        x_high <- all_knots[interval_idx + 1]
        x_sample <- seq(x_low + 1e-6, x_high - 1e-6, length.out = 20)

        basis_matrix <- spline_fn(
          x_sample,
          knots = knots,
          Boundary.knots = boundary_knots,
          intercept = info$intercept
        )
        y_sample <- basis_matrix[, basis_idx]

        coefs <- spline_extract_poly_coefs(x_sample, y_sample, degree = 3)
        coefs_list[[interval_idx]] <- coefs
      }

      eq <- spline_build_case_when(var, all_knots, coefs_list)
      names(eq) <- out_name
      out <- c(out, eq)
    }
  }

  out
}

spline_extract_poly_coefs <- function(x_vals, y_vals, degree = 3) {
  if (all(abs(y_vals) < 1e-14)) {
    return(rep(0, degree + 1))
  }

  fit <- lm(y_vals ~ poly(x_vals, degree, raw = TRUE))
  coefs <- coef(fit)
  coefs[is.na(coefs)] <- 0
  names(coefs) <- NULL
  coefs
}

spline_build_case_when <- function(var, all_knots, coefs_list) {
  n_intervals <- length(coefs_list)
  conditions <- character(n_intervals)

  for (i in seq_len(n_intervals)) {
    coefs <- coefs_list[[i]]

    poly_expr <- spline_build_poly_expr(var, coefs)

    if (i < n_intervals) {
      conditions[i] <- glue::glue("{var} <= {all_knots[i + 1]} ~ {poly_expr}")
    } else {
      conditions[i] <- glue::glue("TRUE ~ {poly_expr}")
    }
  }

  eq <- paste(conditions, collapse = ", ")
  glue::glue("dplyr::case_when({eq})")
}

spline_build_poly_expr <- function(var, coefs) {
  if (all(abs(coefs) < 1e-14)) {
    return("0")
  }

  terms <- character()

  if (abs(coefs[1]) >= 1e-14) {
    terms <- c(terms, format(coefs[1], scientific = FALSE, digits = 15))
  }

  for (power in seq_along(coefs[-1])) {
    coef_val <- coefs[power + 1]
    if (abs(coef_val) >= 1e-14) {
      coef_str <- format(coef_val, scientific = FALSE, digits = 15)
      if (power == 1) {
        terms <- c(terms, glue::glue("{coef_str} * {var}"))
      } else {
        terms <- c(terms, glue::glue("{coef_str} * {var}^{power}"))
      }
    }
  }

  if (length(terms) == 0) {
    return("0")
  }

  paste(terms, collapse = " + ")
}
