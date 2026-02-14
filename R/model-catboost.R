#' @export
orbital.catboost.Model <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL
) {
  mode <- rlang::arg_match(mode)

  type <- default_type(type)

  if (mode == "regression") {
    res <- tidypredict::tidypredict_fit(x)
  } else if (mode == "classification") {
    res <- catboost_binary(x, type, lvl)
  }

  res
}

catboost_binary <- function(x, type, lvl) {
  eq <- tidypredict::tidypredict_fit(x)
  eq <- deparse1(eq)

  res <- NULL
  if ("class" %in% type) {
    levels <- glue::double_quote(lvl)

    res <- c(
      res,
      orbital_tmp_class_name = glue::glue(
        "dplyr::case_when({eq} > 0.5 ~ {levels[2]}, .default = {levels[1]})"
      )
    )
  }
  if ("prob" %in% type) {
    # eq returns P(class 1), so P(class 0) = 1 - eq
    res <- c(
      res,
      orbital_tmp_prob_name1 = glue::glue("1 - ({eq})"),
      orbital_tmp_prob_name2 = glue::glue("{eq}")
    )
  }

  res
}
