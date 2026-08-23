## Evaluate orbital equations against a data frame.
##
## Equations are evaluated in order, each one able to see the columns the
## earlier ones added, which is how orbital's generated code is meant to run.
## Used to check that helpers compute the right values, not just that their
## expression text is stable.
eval_orbital_eqs <- function(eqs, data) {
  for (name in names(eqs)) {
    data[[name]] <- rlang::eval_tidy(
      rlang::parse_expr(eqs[[name]]),
      data = data
    )
  }
  data
}

## For sparklyr testing

testthat_tbl <- function(name, data = NULL, repartition = 0L) {
  sc <- testthat_spark_connection()

  tbl <- tryCatch(dplyr::tbl(sc, name), error = identity)
  if (inherits(tbl, "error")) {
    if (is.null(data)) {
      data <- eval(as.name(name), envir = parent.frame())
    }
    tbl <- dplyr::copy_to(sc, data, name = name, repartition = repartition)
  }

  tbl
}
