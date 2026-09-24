# A neural-network orbital object is meant to have zero heavy runtime
# dependency at prediction time: the whole point of extracting a torch/
# brulee/keras3 fit into plain named expressions is that predicting with it
# afterward needs none of those packages loaded, only `orbital` itself (and
# `dbplyr` for `orbital_sql()`). Building the object in-process and calling
# `predict()`/`orbital_sql()` here wouldn't catch a regression where some
# piece of the object secretly still depends on its source package (e.g. an
# environment closing over a torch tensor), since that package is already
# loaded in this session either way. So this spawns a genuinely fresh `Rscript`
# process that never loads torch/brulee/keras3 at all, to prove predicting
# doesn't need them.
run_in_fresh_session <- function(ob, data) {
  ob_path <- tempfile(fileext = ".rds")
  data_path <- tempfile(fileext = ".rds")
  out_path <- tempfile(fileext = ".rds")
  withr::defer(unlink(c(ob_path, data_path, out_path)))

  saveRDS(ob, ob_path)
  saveRDS(data, data_path)

  script_path <- tempfile(fileext = ".R")
  withr::defer(unlink(script_path))
  writeLines(
    c(
      "args <- commandArgs(trailingOnly = TRUE)",
      "ob <- readRDS(args[[1]])",
      "data <- readRDS(args[[2]])",
      "library(orbital)",
      "preds <- predict(ob, data)",
      "con <- dbplyr::simulate_dbi()",
      "sql <- orbital_sql(ob, con)",
      "saveRDS(",
      "  list(preds = preds, sql = sql, loaded = loadedNamespaces()),",
      "  args[[3]]",
      ")"
    ),
    script_path
  )

  rscript <- file.path(R.home("bin"), "Rscript")
  out <- system2(
    rscript,
    c(
      shQuote(script_path),
      shQuote(ob_path),
      shQuote(data_path),
      shQuote(out_path)
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  if (!file.exists(out_path)) {
    stop("Fresh-session script failed:\n", paste(out, collapse = "\n"))
  }

  readRDS(out_path)
}

expect_no_heavy_dependency <- function(ob, data) {
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("withr")

  result <- run_in_fresh_session(ob, data)

  expect_equal(result$preds, predict(ob, data))
  expect_all_true(!c("torch", "brulee", "keras3") %in% result$loaded)
}

test_that("bare torch nn_sequential predictions need no heavy runtime dependency", {
  skip_if_no_torch()

  model <- torch_seq_model(
    torch::nn_linear(3, 4),
    torch::nn_relu(),
    torch::nn_linear(4, 1)
  )
  ob <- orbital(model, input_names = c("x1", "x2", "x3"))
  data <- data.frame(x1 = rnorm(5), x2 = rnorm(5), x3 = rnorm(5))

  expect_no_heavy_dependency(ob, data)
})

test_that("bare keras3 Sequential predictions need no heavy runtime dependency", {
  skip_if_no_keras()

  model <- keras_seq_model(
    3,
    \(m) keras3::layer_dense(m, 4, activation = "relu"),
    \(m) keras3::layer_dense(m, 1)
  )
  ob <- orbital(model, input_names = c("x1", "x2", "x3"))
  data <- data.frame(x1 = rnorm(5), x2 = rnorm(5), x3 = rnorm(5))

  expect_no_heavy_dependency(ob, data)
})

test_that("mlp(engine = \"brulee\") predictions need no heavy runtime dependency", {
  skip_if_no_brulee()

  fit <- brulee_mlp_fit("regression", mpg ~ disp + hp + wt, scaled_mtcars)
  ob <- orbital(fit)
  data <- scaled_mtcars[c("disp", "hp", "wt")]

  expect_no_heavy_dependency(ob, data)
})
