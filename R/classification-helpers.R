# Shared helper functions for classification models

# Binary classification from a single probability expression
# Assumes: eq is P(second level)
binary_from_prob <- function(eq, type, lvl) {
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
    res <- c(
      res,
      orbital_tmp_prob_name1 = glue::glue("1 - ({eq})"),
      orbital_tmp_prob_name2 = glue::glue("{eq}")
    )
  }
  res
}

# Binary classification from a single probability expression
# Assumes: eq is P(first level)
binary_from_prob_first <- function(eq, type, lvl) {
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

# Generate class selection from logits/scores (pick class with max value)
softmax_class <- function(lvl) {
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

# Multiclass from logits (linear predictors before softmax)
multiclass_from_logits <- function(logit_eqs, type, lvl) {
  res <- stats::setNames(logit_eqs, lvl)

  if ("class" %in% type) {
    res <- c(res, orbital_tmp_class_name = softmax_class(lvl))
  }
  if ("prob" %in% type) {
    norm_eq <- glue::glue_collapse(glue::glue("exp({lvl})"), sep = " + ")
    prob_eqs <- glue::glue("exp({lvl}) / norm")
    names(prob_eqs) <- paste0("orbital_tmp_prob_name", seq_along(lvl))
    res <- c(res, "norm" = norm_eq, prob_eqs)
  }
  res
}

# Multiclass from vote counts
multiclass_from_votes <- function(vote_eqs, type, lvl, n_trees) {
  res <- stats::setNames(vote_eqs, lvl)

  if ("class" %in% type) {
    res <- c(res, orbital_tmp_class_name = softmax_class(lvl))
  }
  if ("prob" %in% type) {
    prob_eqs <- glue::glue("({lvl}) / {n_trees}")
    names(prob_eqs) <- paste0("orbital_tmp_prob_name", seq_along(lvl))
    res <- c(res, prob_eqs)
  }
  res
}

# Multiclass from probability averages
multiclass_from_prob_avg <- function(prob_sum_eqs, type, lvl, n_trees) {
  res <- stats::setNames(prob_sum_eqs, lvl)

  if ("prob" %in% type) {
    prob_eqs <- glue::glue("({lvl}) / {n_trees}")
    names(prob_eqs) <- paste0("orbital_tmp_prob_name", seq_along(lvl))
    res <- c(res, prob_eqs)
  }
  if ("class" %in% type) {
    res <- c(res, orbital_tmp_class_name = softmax_class(lvl))
  }
  res
}
