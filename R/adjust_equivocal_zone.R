#' @export
orbital.equivocal_zone <- function(x, tailor, type, prefix, ...) {
  if (!rlang::is_missing(type) && !(all(c("prob", "class") %in% type))) {
    cli::cli_abort(c(
      x = "{.arg type} must contain {.val prob} and {.val class} to work with 
      {.fn adjust_equivocal_zone}."
    ))
  }

  input <- x$arguments

  out_name <- tailor$columns$estimate
  prob_name <- tailor$columns$probabilities[[1]]

  levels <- gsub("^\\.pred_", "", tailor$columns$probabilities)

  if (prefix != "prefix") {
    out_name <- gsub("^\\.pred", prefix, out_name)
    prob_name <- gsub("^\\.pred", prefix, prob_name)
  }

  out <- glue::glue(
    "dplyr::case_when(
    {prob_name} > {input$threshold} + {input$value} ~ '{levels[1]}',
    {prob_name} < {input$threshold} - {input$value} ~ '{levels[2]}', 
    .default = '[EQ]'
    )"
  )
  names(out) <- out_name
  out
}
