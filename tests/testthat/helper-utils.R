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

## Round a query's numbers for display, then remove the two things about a
## `data.table` query that vary for reasons unrelated to what it computes.
##
## `deparse()` chooses where to break long lines and does not choose the same
## places across R versions, so any snapshot of a query long enough to wrap is
## unstable. And dtplyr numbers its tables from a session-wide counter, so
## `_DT1` becomes `_DT2` whenever an earlier test creates one more table than
## before, which differs between platforms because they skip different tests.
flatten_query <- function(x) {
  x <- gsub("`_DT[0-9]+`", "`_DT`", pretty_print(x))
  gsub("\\s+", " ", paste(x, collapse = " "))
}

## The two non-setosa iris species, as a two-level outcome.
##
## Deliberately not named `binary_iris()`: two test files define a top-level
## function by that name and they do not mean the same thing, one recoding
## setosa against the rest and the other dropping setosa. They do not collide
## because each file gets its own environment, but a shared helper reusing the
## name would.
two_species_iris <- function(levels = c("versicolor", "virginica")) {
  df <- iris[iris$Species != "setosa", ]
  df$Species <- factor(as.character(df$Species), levels = levels)
  df
}
