# Neural network expressions are evaluated against dplyr's namespace, same as
# tree expressions in test-separate-trees.R, since they call `dplyr::if_else()`
# and friends unqualified in some branches.
eval_nn_eqs <- function(eqs, data) {
  for (name in names(eqs)) {
    data[[name]] <- rlang::eval_tidy(
      rlang::parse_expr(eqs[[name]]),
      data = data,
      env = asNamespace("dplyr")
    )
  }
  data
}

test_that("nn_activation_expr() supports every documented activation", {
  expect_identical(nn_activation_expr("x", "relu"), "pmax(x, 0)")
  expect_identical(nn_activation_expr("x", "linear"), "x")
  expect_identical(nn_activation_expr("x", "identity"), "x")
  expect_match(nn_activation_expr("x", "sigmoid"), "exp")
  expect_identical(nn_activation_expr("x", "tanh"), "tanh(x)")
  expect_match(nn_activation_expr("x", "leaky_relu"), "if_else")
  expect_match(nn_activation_expr("x", "elu"), "if_else")
  expect_match(nn_activation_expr("x", "gelu"), "tanh")
})

test_that("nn_activation_expr() errors on an unsupported activation", {
  expect_snapshot(nn_activation_expr("x", "swish"), error = TRUE)
})

test_that("nn_activation_expr() reads activation-specific params", {
  expect_match(
    nn_activation_expr("x", "leaky_relu", list(negative_slope = 0.2)),
    "0.2"
  )
  expect_match(nn_activation_expr("x", "elu", list(alpha = 2)), "2")
})

test_that("nn_activation_expr() computes correct numeric values, default and overridden params", {
  eval_expr <- function(expr, x) {
    rlang::eval_tidy(
      rlang::parse_expr(expr),
      data = list(x = x),
      env = asNamespace("dplyr")
    )
  }

  x <- 1.3
  expect_equal(
    eval_expr(nn_activation_expr("x", "sigmoid"), x),
    1 / (1 + exp(-x))
  )

  x <- -0.7
  expect_equal(
    eval_expr(nn_activation_expr("x", "leaky_relu"), x),
    x * 0.01
  )
  expect_equal(
    eval_expr(
      nn_activation_expr("x", "leaky_relu", list(negative_slope = 0.2)),
      x
    ),
    x * 0.2
  )
  x <- 0.7
  expect_equal(eval_expr(nn_activation_expr("x", "leaky_relu"), x), x)

  x <- -0.5
  expect_equal(
    eval_expr(nn_activation_expr("x", "elu"), x),
    exp(x) - 1
  )
  expect_equal(
    eval_expr(nn_activation_expr("x", "elu", list(alpha = 2)), x),
    2 * (exp(x) - 1)
  )
  x <- 0.5
  expect_equal(eval_expr(nn_activation_expr("x", "elu"), x), x)

  x <- 0.8
  expect_equal(
    eval_expr(nn_activation_expr("x", "gelu"), x),
    0.5 * x * (1 + tanh(sqrt(2 / pi) * (x + 0.044715 * x^3))),
    tolerance = 1e-10
  )
})

test_that("nn_layer_exprs() returns one named expression per output neuron", {
  weight <- matrix(c(1, 2, 3, 4), nrow = 2, byrow = TRUE)
  bias <- c(0.5, -0.5)

  res <- nn_layer_exprs(weight, bias, c("x1", "x2"), "relu", "h1")

  expect_named(res$eqs, c("h1_1", "h1_2"))
  expect_identical(res$names, names(res$eqs))
})

test_that("nn_layer_exprs() computes the right numeric values", {
  weight <- matrix(c(1, -1, 0.5, 2), nrow = 2, byrow = TRUE)
  bias <- c(0.1, -0.2)

  res <- nn_layer_exprs(weight, bias, c("x1", "x2"), "relu", "h1")

  data <- data.frame(x1 = 2, x2 = 3)
  out <- eval_nn_eqs(res$eqs, data)

  expect_equal(out$h1_1, max(2 * 1 + 3 * -1 + 0.1, 0))
  expect_equal(out$h1_2, max(2 * 0.5 + 3 * 2 + -0.2, 0))
})

test_that("a chained network references earlier layers by name, not by re-substituted math", {
  w1 <- matrix(c(0.5, -0.3, 0.2, 0.4), nrow = 2, byrow = TRUE)
  b1 <- c(0.1, -0.2)
  layer1 <- nn_layer_exprs(w1, b1, c("x1", "x2"), "relu", "h1")

  w2 <- matrix(c(0.7, -0.6), nrow = 1)
  b2 <- c(0.05)
  layer2 <- nn_layer_exprs(w2, b2, layer1$names, "identity", "h2")

  # The second layer's expression is short: it references `h1_1`/`h1_2` by
  # name, it doesn't inline layer 1's math a second time.
  expect_match(layer2$eqs[["h2_1"]], "h1_1")
  expect_match(layer2$eqs[["h2_1"]], "h1_2")
  expect_false(grepl("pmax", layer2$eqs[["h2_1"]]))

  data <- data.frame(x1 = 1, x2 = -1)
  out <- eval_nn_eqs(c(layer1$eqs, layer2$eqs), data)

  h1_1 <- max(1 * 0.5 + -1 * -0.3 + 0.1, 0)
  h1_2 <- max(1 * 0.2 + -1 * 0.4 + -0.2, 0)
  expect_equal(out$h1_1, h1_1)
  expect_equal(out$h1_2, h1_2)
  expect_equal(out$h2_1, h1_1 * 0.7 + h1_2 * -0.6 + 0.05)
})

test_that("expression size grows linearly, not exponentially, with depth", {
  # A deep chain of 1-unit layers is the worst case for the inlining blowup
  # this feature exists to avoid: if layer k's expression re-substituted
  # layer k-1's math, character count would double (or more) each layer.
  make_chain <- function(depth) {
    input_names <- c("x1", "x2")
    eqs <- character(0)
    for (i in seq_len(depth)) {
      layer <- nn_layer_exprs(
        matrix(c(0.3, -0.4), nrow = 1),
        0.1,
        input_names,
        "relu",
        paste0("h", i)
      )
      eqs <- c(eqs, layer$eqs)
      input_names <- layer$names
    }
    eqs
  }

  chars_5 <- sum(nchar(make_chain(5)))
  chars_10 <- sum(nchar(make_chain(10)))

  # Linear growth means roughly double the layers is roughly double the total
  # characters; exponential growth would be many orders of magnitude more.
  expect_lt(chars_10, chars_5 * 3)
})

test_that("nn_layer_exprs() batches very wide layers with a forced dependency", {
  n <- 120
  weight <- matrix(rep(1, n * 2), nrow = n)
  bias <- rep(0, n)

  res <- nn_layer_exprs(
    weight,
    bias,
    c("x1", "x2"),
    "identity",
    "h1",
    batch_size = 50
  )

  expect_length(res$eqs, n)
  # Batch 2 (units 51:100) should reference batch 1's last unit as a
  # zero-weighted dependency, and batch 3 should reference batch 2's.
  expect_match(res$eqs[["h1_051"]], "h1_050")
  expect_match(res$eqs[["h1_101"]], "h1_100")
  expect_false(grepl("h1_050", res$eqs[["h1_001"]]))
})

test_that("nn_layer_exprs() does not batch at or below the batch size", {
  n <- 50
  weight <- matrix(rep(1, n * 2), nrow = n)
  bias <- rep(0, n)

  res <- nn_layer_exprs(
    weight,
    bias,
    c("x1", "x2"),
    "identity",
    "h1",
    batch_size = 50
  )

  expect_false(any(grepl("if_else\\(FALSE", res$eqs)))
})

test_that("nn_layer_exprs() batches correctly when the layer isn't a multiple of batch_size", {
  n <- 125
  weight <- matrix(rep(1, n * 2), nrow = n)
  bias <- rep(0, n)

  res <- nn_layer_exprs(
    weight,
    bias,
    c("x1", "x2"),
    "identity",
    "h1",
    batch_size = 50
  )

  expect_match(res$eqs[["h1_051"]], "h1_050")
  expect_match(res$eqs[["h1_101"]], "h1_100")
  # Third batch is a partial batch of 25 (101:125); nothing after it to depend
  # on, so it should carry the dependency on batch 2 same as any other unit.
  expect_match(res$eqs[["h1_125"]], "h1_100")
})

test_that("nn_layer_exprs()'s forced dependency does not corrupt values when the barrier is NaN", {
  # Neuron 1 legitimately evaluates to NaN (0 * Inf); neurons 2 and 3 have
  # finite/Inf values of their own that must not be contaminated by depending
  # on neuron 1 (`+ 0 * NaN` would have turned them into `NaN` too;
  # `if_else(FALSE, ...)` must not).
  weight <- matrix(c(1, 1, 1), nrow = 3)
  bias <- c(-Inf, 0, 0)

  res <- nn_layer_exprs(weight, bias, "x1", "identity", "h1", batch_size = 1)

  data <- data.frame(x1 = Inf)
  out <- eval_nn_eqs(res$eqs, data)

  expect_identical(out$h1_1, NaN)
  expect_equal(out$h1_2, Inf)
  expect_equal(out$h1_3, Inf)
})

test_that("nn_layer_exprs() batching does not change the numeric result", {
  n <- 60
  set.seed(1)
  weight <- matrix(runif(n * 2, -1, 1), nrow = n)
  bias <- runif(n, -1, 1)

  batched <- nn_layer_exprs(
    weight,
    bias,
    c("x1", "x2"),
    "relu",
    "h1",
    batch_size = 50
  )
  unbatched <- nn_layer_exprs(
    weight,
    bias,
    c("x1", "x2"),
    "relu",
    "h1",
    batch_size = n
  )

  data <- data.frame(x1 = 0.5, x2 = -0.5)
  out_batched <- eval_nn_eqs(batched$eqs, data)
  out_unbatched <- eval_nn_eqs(unbatched$eqs, data)

  expect_equal(
    as.numeric(out_batched[batched$names]),
    as.numeric(out_unbatched[unbatched$names])
  )
})

test_that("nn_layer_exprs() output compiles to nested SELECT subqueries", {
  skip_if_not_installed("dbplyr")

  w1 <- matrix(c(0.5, -0.3, 0.2, 0.4), nrow = 2, byrow = TRUE)
  layer1 <- nn_layer_exprs(w1, c(0.1, -0.2), c("x1", "x2"), "relu", "h1")

  w2 <- matrix(c(0.7, -0.6), nrow = 1)
  layer2 <- nn_layer_exprs(w2, 0.05, layer1$names, "identity", "h2")

  all_eqs <- c(layer1$eqs, layer2$eqs)
  eqs <- stats::setNames(
    lapply(all_eqs, rlang::parse_expr),
    names(all_eqs)
  )
  lazy_tbl <- dbplyr::lazy_frame(x1 = 1, x2 = 1, con = dbplyr::simulate_dbi())

  query <- rlang::inject(dplyr::mutate(lazy_tbl, !!!eqs))
  sql <- dbplyr::sql_render(query)

  # Two layers, both depending on the previous, should produce nested
  # subqueries rather than one flat SELECT: at least two SELECTs, with the
  # outer one's FROM clause opening a parenthesized inner query rather than
  # just naming a table.
  expect_gte(lengths(regmatches(sql, gregexpr("SELECT", sql))), 2)
  expect_match(sql, "FROM\\s*\\(")
})

test_that("nn_output_eqs() returns .pred directly for a regression network", {
  res <- nn_output_eqs(c(out = "1 + 2"), "identity", mode = "regression")
  expect_named(res, ".pred")
  expect_identical(unname(res), "1 + 2")
})

test_that("nn_output_eqs() errors for a multi-unit regression network", {
  expect_snapshot(
    nn_output_eqs(c(a = "1", b = "2"), "identity", mode = "regression"),
    error = TRUE
  )
})

test_that("nn_output_eqs() errors for a bound regression activation", {
  expect_snapshot(
    nn_output_eqs(c(out = "1"), "sigmoid", mode = "regression"),
    error = TRUE
  )
})

test_that("nn_output_eqs() routes single-unit sigmoid to binary_from_prob_first() with correct probabilities", {
  res <- nn_output_eqs(
    c(out = "1.5"),
    "sigmoid",
    mode = "classification",
    type = c("class", "prob"),
    lvl = c("yes", "no")
  )

  out <- eval_nn_eqs(res, data.frame(row = 1))
  p_yes <- 1 / (1 + exp(-1.5))

  expect_equal(out$orbital_tmp_prob_name1, p_yes)
  expect_equal(out$orbital_tmp_prob_name2, 1 - p_yes)
  expect_identical(out$orbital_tmp_class_name, "yes")
})

test_that("nn_output_eqs() treats a single raw logit (no explicit sigmoid module) as binary classification", {
  # A bare single-unit output with a `linear`/`identity` final activation is
  # what a model trained with e.g. `nn_bce_with_logits_loss()` produces: it
  # never adds a terminal `nn_sigmoid()`, so the raw logit itself is what's
  # stored. This must produce the exact same probabilities as an explicit
  # `sigmoid` final layer given the same raw value.
  res_identity <- nn_output_eqs(
    c(out = "1.5"),
    "identity",
    mode = "classification",
    type = c("class", "prob"),
    lvl = c("yes", "no")
  )
  res_linear <- nn_output_eqs(
    c(out = "1.5"),
    "linear",
    mode = "classification",
    type = c("class", "prob"),
    lvl = c("yes", "no")
  )
  res_sigmoid <- nn_output_eqs(
    c(out = "1.5"),
    "sigmoid",
    mode = "classification",
    type = c("class", "prob"),
    lvl = c("yes", "no")
  )

  expect_identical(res_identity, res_sigmoid)
  expect_identical(res_linear, res_sigmoid)
})

test_that("nn_output_eqs() errors on sigmoid with two or more output units", {
  expect_snapshot(
    nn_output_eqs(
      c(a = "1", b = "2"),
      "sigmoid",
      mode = "classification",
      type = "class",
      lvl = c("a", "b")
    ),
    error = TRUE
  )
})

test_that("nn_output_eqs() errors on softmax with a single output unit", {
  expect_snapshot(
    nn_output_eqs(
      c(out = "1"),
      "softmax",
      mode = "classification",
      type = "class",
      lvl = c("yes", "no")
    ),
    error = TRUE
  )
})

test_that("nn_output_eqs() routes multi-unit linear output to multiclass_from_logits() with correct probabilities", {
  res <- nn_output_eqs(
    c(a = "1", b = "2", c = "3"),
    "identity",
    mode = "classification",
    type = c("class", "prob"),
    lvl = c("a", "b", "c")
  )

  out <- eval_nn_eqs(res, data.frame(row = 1))
  denom <- exp(1) + exp(2) + exp(3)

  expect_equal(out$orbital_tmp_prob_name1, exp(1) / denom)
  expect_equal(out$orbital_tmp_prob_name2, exp(2) / denom)
  expect_equal(out$orbital_tmp_prob_name3, exp(3) / denom)
  expect_identical(out$orbital_tmp_class_name, "c")
})

test_that("nn_output_eqs() treats linear and identity as equivalent aliases", {
  args <- list(
    linear_eqs = c(a = "1", b = "2", c = "3"),
    mode = "classification",
    type = c("class", "prob"),
    lvl = c("a", "b", "c")
  )

  res_linear <- rlang::exec(nn_output_eqs, !!!args, activation = "linear")
  res_identity <- rlang::exec(nn_output_eqs, !!!args, activation = "identity")

  expect_identical(res_linear, res_identity)
})

test_that("nn_output_eqs() routes an explicit softmax final layer like a bare linear one", {
  # The final layer's stored weights/bias are always pre-activation logits
  # regardless of whether the model's own final activation is an explicit
  # softmax module or a bare linear layer with softmax applied at serve time;
  # both should produce the same routed expressions.
  res_softmax <- nn_output_eqs(
    c(a = "1", b = "2", c = "3"),
    "softmax",
    mode = "classification",
    type = c("class", "prob"),
    lvl = c("a", "b", "c")
  )
  res_identity <- nn_output_eqs(
    c(a = "1", b = "2", c = "3"),
    "identity",
    mode = "classification",
    type = c("class", "prob"),
    lvl = c("a", "b", "c")
  )

  expect_identical(res_softmax, res_identity)
})

test_that("nn_output_eqs() errors on an unsupported final activation (single output unit)", {
  expect_snapshot(
    nn_output_eqs(c(out = "1"), "tanh", mode = "classification"),
    error = TRUE
  )
})

test_that("nn_output_eqs() errors on an unsupported final activation (two or more output units)", {
  expect_snapshot(
    nn_output_eqs(c(a = "1", b = "2"), "tanh", mode = "classification"),
    error = TRUE
  )
})

test_that("nn_layer_exprs() preserves full digits17 precision for non-terminating weights and biases", {
  res <- nn_layer_exprs(matrix(0.1), 0.2, "x1", "identity", "h1")

  # `format_numeric()`'s whole reason to exist: a `deparse1(control =
  # "digits17")` round-trip must be exact, not just close, so the SQL literal
  # reproduces the source model's float bit-for-bit (modulo the existing
  # `capabilities("long.double")` caveat documented in `?orbital`). Both the
  # weight and the bias go through the same `build_linear_pred()` call, but
  # each is checked explicitly since either could regress independently.
  weight_literal <- regmatches(
    res$eqs[["h1_1"]],
    regexpr("0\\.1000000000000000\\d+", res$eqs[["h1_1"]])
  )
  expect_identical(as.numeric(weight_literal), 0.1)

  bias_literal <- regmatches(
    res$eqs[["h1_1"]],
    regexpr("0\\.2000000000000000\\d+", res$eqs[["h1_1"]])
  )
  expect_identical(as.numeric(bias_literal), 0.2)
})
