pretty_print <- function(x) {
  old_values <- regmatches(x, gregexpr( "[0-9]+\\.?[0-9]+", x))
  new_values <- lapply(old_values, function(x) signif(as.numeric(x), 7))
  
  old_values <- unlist(old_values, use.names = FALSE)
  new_values <- unlist(new_values, use.names = FALSE)
  
  for (i in seq_along(old_values)) {
    x <- gsub(old_values[i], new_values[i], x)
  } 
  
  x
}