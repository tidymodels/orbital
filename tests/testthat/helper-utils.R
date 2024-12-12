## For sparklyr testing

testthat_tbl <- function(name, data = NULL, repartition = 0L) {
	sc <- testthat_spark_connection()

	tbl <- tryCatch(dplyr::tbl(sc, name), error = identity)
	if (inherits(tbl, "error")) {
		if (is.null(data)) data <- eval(as.name(name), envir = parent.frame())
		tbl <- dplyr::copy_to(sc, data, name = name, repartition = repartition)
	}

	tbl
}
