#' @export
orbital.model_fit <- function(x, ...) {
  res <- tryCatch(
    tidypredict::tidypredict_fit(x),
    error = function(cnd) {
      if (grepl("no applicable method for", cnd$message)) {
        cls <- class(x)
        cls <- setdiff(cls, "model_fit")
        cls <- gsub("^_", "", cls)

        cli::cli_abort(
          "A model of class {.cls {cls}} is not supported.",
          call = rlang::call2("orbital")
        )
      }
      stop(cnd)
    }
  )

  res <- c(".pred" = deparse1(res))
  
  new_orbital_class(res)
}

#' @export
orbital.model_spec <- function(x, ...) {
  cli::cli_abort("{.arg x} must be fitted model.")
}
