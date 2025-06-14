testthat_init <- function() {
  options(timeout = 3600)
  options(sparklyr.connect.timeout = 300)
  options(livy.session.start.timeout = 300)
  suppressPackageStartupMessages(library(sparklyr))
  suppressPackageStartupMessages(library(dplyr))
  if (using_arrow()) {
    suppressPackageStartupMessages(library(arrow))
  }
  testthat_addl_libraries()
}

testthat_spark_connection <- function() {
  suppressMessages(
    if (!testthat_spark_connection_open()) {
      testthat_init()
      tp <- testthat_spark_connection_type()
      if (tp == "method") sc <- testthat_method_connection()
      if (tp == "databricks")
        sc <- testthat_shell_connection(method = "databricks")
      if (tp == "synapse") sc <- testthat_shell_connection(method = "synapse")
      if (tp == "local") sc <- testthat_shell_connection()
      if (tp == "livy") sc <- testthat_livy_connection()
    } else {
      sc <- testthat_spark_connection_object()
    }
  )

  sc
}

testthat_method_connection <- function() {
  sc <- sparklyr::spark_connect(
    master = using_master_get(),
    method = using_method_get()
  )
  testthat_spark_connection_object(sc)
  sc
}

testthat_shell_connection <- function(method = "shell") {
  connected <- testthat_spark_connection_open()
  spark_version <- testthat_spark_env_version()

  if (connected) {
    sc <- testthat_spark_connection_object()
    connected <- sparklyr::connection_is_open(sc)
  }

  if (Sys.getenv("INSTALL_WINUTILS") == "true") {
    spark_install_winutils(spark_version)
  }

  if (!connected) {
    options(sparklyr.sanitize.column.names.verbose = TRUE)
    options(sparklyr.verbose = TRUE)
    options(sparklyr.na.omit.verbose = TRUE)
    options(sparklyr.na.action.verbose = TRUE)

    config <- sparklyr::spark_config()
    config[["sparklyr.shell.driver-memory"]] <- "3G"
    config[["sparklyr.apply.env.foo"]] <- "env-test"
    config[["spark.sql.warehouse.dir"]] <- get_spark_warehouse_dir()
    if (identical(.Platform$OS.type, "windows")) {
      # TODO: investigate why there are Windows-specific timezone portability issues
      config[["spark.sql.session.timeZone"]] <- "UTC"
    }
    config$`sparklyr.sdf_collect.persistence_level` <- "NONE"

    packages <- NULL
    if (spark_version >= "2.4.2") packages <- c(packages, "delta")

    sc <- sparklyr::spark_connect(
      master = "local",
      method = method,
      version = spark_version,
      config = config,
      packages = packages
    )

    testthat_spark_connection_object(sc)
  }
  sc
}

testthat_livy_connection <- function() {
  if (!testthat_spark_connection_open()) {
    if (Sys.getenv("INSTALL_WINUTILS") == "true") {
      spark_install_winutils(version)
    }

    spark_version <- testthat_spark_env_version()

    sparklyr::livy_service_start(
      version = using_livy_version(),
      spark_version = spark_version
    )

    wait_for_svc(
      svc_name = "livy",
      port = 8998,
      timeout_s = 30
    )

    sc <- sparklyr::spark_connect(
      master = "http://localhost:8998",
      method = "livy",
      version = spark_version
    )

    testthat_spark_connection_object(sc)
  }

  testthat_spark_connection_object()
}

wait_for_svc <- function(svc_name, port, timeout_s) {
  suppressWarnings({
    socket <- NULL
    on.exit(
      if (!is.null(socket)) {
        close(socket)
      }
    )
    for (t in 1:timeout_s) {
      try(
        socket <- socketConnection(
          host = "localhost",
          port = port,
          server = FALSE,
          open = "r+"
        ),
        silent = TRUE
      )
      if (is.null(socket)) {
        sprintf("Waiting for %s socket to be in listening state...", svc_name)
        Sys.sleep(1)
      } else {
        break
      }
    }
  })
}

get_spark_warehouse_dir <- function() {
  ifelse(.Platform$OS.type == "windows", Sys.getenv("TEMP"), tempfile())
}

spark_install_winutils <- function(version) {
  hadoop_version <- if (version < "2.0.0") "2.6" else "2.7"
  spark_dir <- paste("spark-", version, "-bin-hadoop", hadoop_version, sep = "")
  winutils_dir <- file.path(
    Sys.getenv("LOCALAPPDATA"),
    "spark",
    spark_dir,
    "tmp",
    "hadoop",
    "bin",
    fsep = "\\"
  )

  if (!dir.exists(winutils_dir)) {
    message("Installing winutils...")

    dir.create(winutils_dir, recursive = TRUE)
    winutils_path <- file.path(winutils_dir, "winutils.exe", fsep = "\\")

    download.file(
      "https://github.com/steveloughran/winutils/raw/master/hadoop-2.6.0/bin/winutils.exe",
      winutils_path,
      mode = "wb"
    )

    message("Installed winutils in ", winutils_path)
  }
}

testthat_addl_libraries <- function() {
  libs <- Sys.getenv("TEST_SPARKLYR_LIBRARIES", unset = NA)
  if (!is.na(libs)) {
    sep_libs <- unlist(strsplit(libs, ";"))
    invisible(
      lapply(sep_libs, function(x) {
        c_libs <- trimws(x)
        suppressPackageStartupMessages(
          library(c_libs, character.only = TRUE)
        )
      })
    )
  }
}
