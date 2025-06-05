#' @export
orbital.xgb.Booster <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL
) {
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (mode == "classification") {
    objective <- x$params$objective
    objective <- rlang::arg_match0(
      objective,
      c("multi:softprob", "binary:logistic")
    )

    extractor <- switch(
      objective,
      "multi:softprob" = xgboost_multisoft,
      "binary:logistic" = xgboost_logistic
    )

    res <- extractor(x, type, lvl)
  } else if (mode == "regression") {
    res <- tidypredict::tidypredict_fit(x)
  }
  res
}

xgboost_multisoft <- function(x, type, lvl) {
  trees <- tidypredict::.extract_xgb_trees(x)

  trees_split <- split(trees, rep(seq_along(lvl), x$niter))
  trees_split <- lapply(trees_split, collapse_stumps)
  trees_split <- vapply(trees_split, paste, character(1), collapse = " + ")

  res <- stats::setNames(trees_split, lvl)

  if ("class" %in% type) {
    res <- c(
      res,
      orbital_tmp_class_name = softmax(lvl)
    )
  }
  if ("prob" %in% type) {
    eqs <- glue::glue("exp({lvl}) / norm")
    names(eqs) <- paste0("orbital_tmp_prob_name", seq_along(lvl))

    res <- c(
      res,
      "norm" = glue::glue_collapse(glue::glue("exp({lvl})"), sep = " + "),
      eqs
    )
  }
  res
}

collapse_stumps <- function(x) {
  stump_ind <- lengths(x) == 2

  stumps <- x[stump_ind]
  trees <- x[!stump_ind]

  stump_values <- lapply(stumps, function(x) eval(x[[2]][[3]]))
  stump_values <- unlist(stump_values)
  stump_values <- sum(stump_values)

  c(stump_values, trees)
}

xgboost_logistic <- function(x, type, lvl) {
  eq <- tidypredict::tidypredict_fit(x)

  eq <- deparse1(eq)

  res <- NULL
  if ("class" %in% type) {
    levels <- glue::double_quote(lvl)

    res <- c(
      res,
      orbital_tmp_class_name = glue::glue(
        "dplyr::case_when({eq} > 0.5 ~ {levels[1]}, .default = {levels[2]})"
      )
    )
  }
  if ("prob" %in% type) {
    res <- c(
      res,
      orbital_tmp_prob_name1 = glue::glue("{eq}"),
      orbital_tmp_prob_name2 = glue::glue("1 - ({eq})")
    )
  }
  res
}

softmax <- function(lvl) {
  res <- character(0)

  for (i in seq(1, length(lvl) - 1)) {
    line <- glue::glue("{lvl[i]} > {lvl[-i]}")
    line <- glue::glue_collapse(line, sep = " & ")
    line <- glue::glue("{line} ~ {glue::double_quote(lvl[i])}")
    res[i] <- line
  }

  res <- glue::glue_collapse(res, ", ")
  default <- glue::double_quote(lvl[length(lvl)])

  glue::glue("dplyr::case_when({res}, .default = {default})")
}
