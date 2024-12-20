namespace_case_when <- function(x) {
	names <- names(x)
	x <- gsub("dplyr::case_when", "case_when", x)
	x <- gsub("case_when", "dplyr::case_when", x)
	names(x) <- names
	x
}
