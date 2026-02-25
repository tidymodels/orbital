#' @export
orbital.probability_threshold <- function(x, tailor, type, prefix, ...) {
  if (!rlang::is_missing(type) && !(all(c("prob", "class") %in% type))) {
    cli::cli_abort(c(
      x = "{.arg type} must contain {.val prob} and {.val class} to work with 
      {.fn adjust_equivocal_zone}."
    ))
  }

  input <- x$arguments

  prob_name <- tailor$columns$probabilities[[1]]

  levels <- gsub("^\\.pred_", "", tailor$columns$probabilities)

  out_name <- paste0(prefix, "_class")

  if (prefix != "prefix") {
    prob_name <- gsub("^\\.pred", prefix, prob_name)
  }

  threshold_fmt <- format_numeric(input$threshold)
  out <- glue::glue(
    "dplyr::case_when(
    {prob_name} > {threshold_fmt} ~ '{levels[1]}',
    {prob_name} < {threshold_fmt} ~ '{levels[2]}',
    .default = '[EQ]'
    )"
  )
  names(out) <- out_name
  out
}
