# Feed-forward neural network expression generation (issue #149), shared by
# every `orbital.*` back end added on top of it (torch, brulee, keras3).
#
# The core idea, matching `R/separate-trees.R`'s tree-per-column pattern: give
# every neuron its own named column instead of substituting one layer's
# expression into the next layer's. Later layers then reference earlier
# layers by name, so a single `dplyr::mutate()` call compiles to correctly
# nested `SELECT` subqueries instead of an expression that grows exponentially
# with depth. There is no optimization pass to write, just this naming rule.
#
# This file has no public API yet: it's fed synthetic weight matrices
# directly by its own tests. `orbital.nn_sequential()` and friends (later
# milestones) call into it once there's a real fitted model to extract from.

nn_activations <- c(
  "relu",
  "sigmoid",
  "tanh",
  "linear",
  "identity",
  "leaky_relu",
  "elu",
  "gelu"
)

# Shape-based inference shared by every `orbital.*` back end built on top of
# `nn_sequential_layers()`: a network with more than one output unit is never
# regression in this package (`nn_output_eqs()` only allows a single-unit
# regression output), so it's unambiguously classification even without a
# trailing sigmoid/softmax module (e.g. a bare final linear layer trained
# with a cross-entropy loss, which never adds one).
nn_infer_mode <- function(n_out, final_activation) {
  if (n_out > 1 || final_activation %in% c("sigmoid", "softmax")) {
    "classification"
  } else {
    "regression"
  }
}

nn_default_lvl <- function(n_out) {
  paste0("class_", seq_len(max(n_out, 2)) - 1)
}

# Validates a user-supplied `lvl` against the length `nn_output_eqs()`
# actually consumes: 2 for a single output unit (always routed as binary
# classification through a sigmoid), or `n_out` for two or more. Left
# unchecked, a too-short `lvl` silently drops the last class/level instead of
# erroring.
nn_check_lvl <- function(lvl, n_out, call = rlang::caller_env()) {
  if (is.null(lvl)) {
    return(invisible())
  }

  expected <- max(n_out, 2)
  if (length(lvl) != expected) {
    cli::cli_abort(
      c(
        "{.arg lvl} must have length {expected}, not {length(lvl)}.",
        i = if (n_out == 1) {
          "A single output unit is always treated as binary classification,
           which requires 2 levels."
        } else {
          "The network has {n_out} output units."
        }
      ),
      call = call
    )
  }
}

# Validates a user-supplied `input_names` against the first layer's actual
# input width. Left unchecked, a too-short `input_names` silently drops the
# last feature instead of erroring.
nn_check_input_names <- function(
  input_names,
  n_in,
  call = rlang::caller_env()
) {
  if (length(input_names) != n_in) {
    cli::cli_abort(
      "{.arg input_names} has length {length(input_names)}, but the first
       layer expects {n_in} input{?s}.",
      call = call
    )
  }
}

# Wrap one neuron's linear-predictor expression (already full precision,
# already backtick-quoted variable references, as returned by
# `build_linear_pred()`) in its activation function. `params` carries any
# activation-specific tuning value already read off the fitted layer (e.g.
# `negative_slope` for leaky_relu, `alpha` for elu).
#
# gelu always uses the tanh-approximation form, even for a source model that
# requested the exact erf-based variant: `erf` has no SQL-translatable form,
# so this is a deliberate, documented approximation rather than a refusal.
nn_activation_expr <- function(
  x,
  activation,
  params = list(),
  call = rlang::caller_env()
) {
  switch(
    activation,
    relu = glue::glue("pmax({x}, 0)"),
    sigmoid = glue::glue("1 / (1 + exp(-({x})))"),
    tanh = glue::glue("tanh({x})"),
    linear = x,
    identity = x,
    leaky_relu = {
      slope <- format_numeric(params$negative_slope %||% 0.01)
      glue::glue("dplyr::if_else(({x}) > 0, {x}, ({x}) * {slope})")
    },
    elu = {
      alpha <- format_numeric(params$alpha %||% 1)
      glue::glue("dplyr::if_else(({x}) > 0, {x}, {alpha} * (exp({x}) - 1))")
    },
    gelu = glue::glue(
      "0.5 * ({x}) * (1 + tanh(0.7978845608028654 * (({x}) + 0.044715 * ({x})^3)))"
    ),
    cli::cli_abort(
      c(
        "Activation {.val {activation}} is not supported.",
        i = "Supported activations are: {.val {nn_activations}}."
      ),
      call = call
    )
  )
}

# A fixed per-channel affine transform, read directly off a fitted
# BatchNorm layer's own stored statistics/parameters (never recomputed from
# the current batch, which is what makes this representable as a plain SQL
# expression at all): `(x - running_mean) / sqrt(running_var + eps) * gamma +
# beta`. Applied to one neuron's raw (pre-activation) expression before
# `nn_activation_expr()` wraps it.
nn_batch_norm_expr <- function(x, norm, i) {
  mean_i <- format_numeric(norm$running_mean[i])
  var_i <- format_numeric(norm$running_var[i])
  eps <- format_numeric(norm$eps)
  gamma_i <- format_numeric(norm$gamma[i])
  beta_i <- format_numeric(norm$beta[i])
  glue::glue(
    "(({x}) - {mean_i}) / sqrt({var_i} + {eps}) * {gamma_i} + {beta_i}"
  )
}

# One hidden layer's worth of neuron columns.
#
# `weight` is a matrix with one row per output neuron and one column per input
# (the orientation `build_linear_pred()` wants; callers reading torch's
# `out x in` layout can pass it straight through, callers reading keras's
# `in x out` layout need to transpose first). `bias` is a vector, one entry
# per output neuron. `input_names` are the column names feeding this layer
# (either the model's own feature names, for the first layer, or the previous
# layer's returned `names`).
#
# `norm`, if not `NULL`, is a fitted normalization layer's config (see
# `nn_batch_norm_expr()` above and `nn_layer_exprs_layer_norm()` below),
# applied between the raw linear predictor and the activation, matching where
# BatchNorm/LayerNorm actually sit in a real network.
#
# Returns `list(eqs, names, extra)`: `eqs` is a named character vector, one
# expression per output neuron; `names` is `names(eqs)`, handed back so the
# caller can thread it in as the next layer's `input_names`; `extra` is any
# additional intermediate columns that had to be materialized to compute
# `eqs` but aren't themselves per-neuron outputs (empty except for
# `norm$type == "layer_norm"`, see below).
#
# `batch_size` guards against very wide layers hitting a database's
# per-`SELECT`-list column limit, mirroring `tree_columns()`'s batching. Since
# neurons in the same layer don't depend on each other the way tree sums do,
# there's nothing to combine — instead each batch after the first carries a
# reference to the previous batch's last neuron, which doesn't change any
# neuron's value but does give dbplyr a name dependency to nest a subquery
# boundary on. That reference goes through `dplyr::if_else(FALSE, ...)`
# rather than a zero-weighted arithmetic term (`+ 0 * x`): SQL's `CASE WHEN`
# only evaluates the branch it selects, so an `if_else(FALSE, ...)` never
# touches the referenced value even if it's `NaN`/`Inf` (as can happen after
# `sigmoid`/`gelu`/`exp` on extreme inputs); `+ 0 * NaN` is still `NaN` and
# would have silently corrupted every neuron in the next batch. This is
# otherwise a placeholder mechanism (see the dev plan's "still open" note)
# and may be revisited once there's a concrete case that needs it.
nn_layer_exprs <- function(
  weight,
  bias,
  input_names,
  activation,
  layer_prefix,
  params = list(),
  norm = NULL,
  batch_size = 50
) {
  n_out <- nrow(weight)
  width <- nchar(as.character(n_out))
  out_names <- sprintf(paste0(layer_prefix, "_%0", width, "d"), seq_len(n_out))

  if (!is.null(norm) && norm$type == "layer_norm") {
    return(nn_layer_exprs_layer_norm(
      weight,
      bias,
      input_names,
      activation,
      layer_prefix,
      params,
      norm,
      out_names,
      batch_size
    ))
  }

  batch_indices <- split(seq_len(n_out), ceiling(seq_len(n_out) / batch_size))

  exprs <- stats::setNames(character(n_out), out_names)
  barrier <- NULL

  for (idx in batch_indices) {
    for (i in idx) {
      lin <- build_linear_pred(
        c("(Intercept)", input_names),
        c(bias[i], weight[i, ])
      )
      if (!is.null(barrier)) {
        lin <- paste0(
          "dplyr::if_else(FALSE, ",
          backtick(barrier),
          ", ",
          lin,
          ")"
        )
      }
      if (!is.null(norm)) {
        lin <- nn_batch_norm_expr(lin, norm, i)
      }
      exprs[[out_names[i]]] <- nn_activation_expr(lin, activation, params)
    }
    barrier <- out_names[idx[length(idx)]]
  }

  list(eqs = exprs, names = out_names, extra = character(0))
}

# LayerNorm normalizes each row over the layer's own neurons at inference
# time (mean/variance computed from the current row, not read off fixed
# running statistics the way BatchNorm's are), so unlike
# `nn_batch_norm_expr()` this can't fold into each neuron's own independent
# expression: every neuron in the layer needs every other neuron's raw
# (pre-normalization) value first. This materializes those raw values as
# their own intermediate columns (`<layer_prefix>_ln_raw_<i>`, never matched
# by `nn_output_layer_names()`'s `output_layer` grep, which only matches the
# final `<layer_prefix>_<zero-padded index>` names), then a shared mean/
# variance pair, then the final normalized + affine + activated value per
# neuron referencing those by name.
nn_layer_exprs_layer_norm <- function(
  weight,
  bias,
  input_names,
  activation,
  layer_prefix,
  params,
  norm,
  out_names,
  batch_size
) {
  n_out <- nrow(weight)
  raw_names <- paste0(layer_prefix, "_ln_raw_", seq_len(n_out))

  batch_indices <- split(seq_len(n_out), ceiling(seq_len(n_out) / batch_size))
  raw_exprs <- stats::setNames(character(n_out), raw_names)
  barrier <- NULL

  for (idx in batch_indices) {
    for (i in idx) {
      lin <- build_linear_pred(
        c("(Intercept)", input_names),
        c(bias[i], weight[i, ])
      )
      if (!is.null(barrier)) {
        lin <- paste0(
          "dplyr::if_else(FALSE, ",
          backtick(barrier),
          ", ",
          lin,
          ")"
        )
      }
      raw_exprs[[raw_names[i]]] <- lin
    }
    barrier <- raw_names[idx[length(idx)]]
  }

  mean_name <- paste0(layer_prefix, "_ln_mean")
  var_name <- paste0(layer_prefix, "_ln_var")
  mean_expr <- paste0(
    "(",
    paste(backtick(raw_names), collapse = " + "),
    ") / ",
    n_out
  )
  dev_terms <- paste0(
    "(",
    backtick(raw_names),
    " - ",
    backtick(mean_name),
    ")^2"
  )
  var_expr <- paste0("(", paste(dev_terms, collapse = " + "), ") / ", n_out)

  stat_exprs <- stats::setNames(c(mean_expr, var_expr), c(mean_name, var_name))

  eps <- format_numeric(norm$eps)
  exprs <- stats::setNames(character(n_out), out_names)
  for (i in seq_len(n_out)) {
    gamma_i <- format_numeric(norm$gamma[i])
    beta_i <- format_numeric(norm$beta[i])
    normed <- glue::glue(
      "(({backtick(raw_names[i])}) - {backtick(mean_name)}) / sqrt({backtick(var_name)} + {eps}) * {gamma_i} + {beta_i}"
    )
    exprs[[out_names[i]]] <- nn_activation_expr(normed, activation, params)
  }

  list(eqs = exprs, names = out_names, extra = c(raw_exprs, stat_exprs))
}

# Shared by `orbital.nn_sequential()` and `orbital.brulee_mlp()`: walks
# `layers` (as produced by `nn_sequential_layers()`) forward, materializing
# every hidden layer's neuron columns and returning the final layer's raw
# (pre-activation) linear expressions separately, since final-layer routing
# (`nn_output_eqs()`) needs to see the fitted activation string alongside
# them rather than have it already applied.
#
# `prefix` namespaces the generated column names (`<prefix>_L<layer>_<unit>`),
# letting a multi-output network's trunk and each head walk with disjoint
# names instead of every call defaulting to the same `orbital_nn_L*` names and
# colliding. `activate_final`, used only by the trunk side of a multi-output
# network, treats every layer as hidden (materializing the last layer's
# activated output like any other) instead of holding it back as
# `linear_eqs`: a trunk's output feeds a head's first layer as real
# already-activated values, not a set of logits awaiting `nn_output_eqs()`
# routing. `names`, the last layer's output column names, is always returned
# so a caller (the multi-output orchestrator) can thread it into the next
# call's `input_names` without recomputing it.
nn_forward_eqs <- function(
  layers,
  input_names,
  prefix = "orbital_nn",
  activate_final = FALSE
) {
  hidden_eqs <- character(0)
  linear_eqs <- NULL
  names_in <- input_names

  for (i in seq_along(layers)) {
    layer <- layers[[i]]
    is_last <- i == length(layers)
    treat_as_hidden <- !is_last || activate_final

    layer_res <- nn_layer_exprs(
      layer$weight,
      layer$bias,
      names_in,
      activation = if (treat_as_hidden) layer$activation else "linear",
      layer_prefix = sprintf(paste0(prefix, "_L%d"), i),
      params = if (treat_as_hidden) layer$params else list(),
      norm = layer$norm
    )

    hidden_eqs <- c(hidden_eqs, layer_res$extra)
    if (treat_as_hidden) {
      hidden_eqs <- c(hidden_eqs, layer_res$eqs)
    } else {
      linear_eqs <- layer_res$eqs
    }
    names_in <- layer_res$names
  }

  list(hidden_eqs = hidden_eqs, linear_eqs = linear_eqs, names = names_in)
}

# Validates a user-supplied `output_layer` against the number of hidden
# layers `nn_forward_eqs()` actually materializes as their own columns (layers
# 1..(n_layers - 1); the final layer's pre-activation values are never stored
# under their own names, so requesting it isn't meaningful here). Returns the
# requested layer's neuron column names, in the same order `nn_layer_exprs()`
# generated them, to append to `pred_names` alongside the usual `.pred*`
# columns.
nn_output_layer_names <- function(
  hidden_eqs,
  output_layer,
  n_layers,
  call = rlang::caller_env()
) {
  if (is.null(output_layer)) {
    return(NULL)
  }

  if (
    length(output_layer) != 1 ||
      !is.numeric(output_layer) ||
      output_layer != as.integer(output_layer) ||
      output_layer < 1 ||
      output_layer >= n_layers
  ) {
    cli::cli_abort(
      "{.arg output_layer} must be a single integer between 1 and
       {n_layers - 1}, not {.val {output_layer}}.",
      call = call
    )
  }

  # Anchored to digits-only suffixes so this only ever matches the per-neuron
  # output names `nn_layer_exprs()` returns as `eqs`, never a LayerNorm
  # layer's intermediate `_ln_raw_*`/`_ln_mean`/`_ln_var` columns (which also
  # start with the same `orbital_nn_L<i>_` prefix but aren't outputs).
  grep(
    sprintf("^orbital_nn_L%d_[0-9]+$", output_layer),
    names(hidden_eqs),
    value = TRUE
  )
}

# Final-layer routing: given the last layer's raw affine (pre-activation)
# expressions and its declared activation, dispatch to the existing
# classification helpers (`R/classification-helpers.R`) or return the
# regression prediction directly. No new classification math lives here,
# only the decision of which existing helper applies.
#
# A single output unit is always routed as binary classification through a
# sigmoid, regardless of whether `activation` says "sigmoid" (an explicit
# module) or "linear"/"identity" (a bare raw logit, e.g. a torch model
# trained with `nn_bce_with_logits_loss()`, which never adds a terminal
# `nn_sigmoid()`): `linear_eqs` is pre-activation either way, so both shapes
# need the same sigmoid applied here before routing to
# `binary_from_prob_first()`.
#
# An explicit "softmax" final layer is routed identically to a bare
# "linear"/"identity" one: softmax cannot be computed per neuron (it needs
# the whole layer's values at once to normalize), so `nn_layer_exprs()` never
# actually materializes it — the stored values for a "softmax"-labelled final
# layer are, structurally, always the pre-softmax logits, exactly like the
# bare-linear case. `multiclass_from_logits()` (which computes `exp(x)/sum
# (exp(x))` itself) is therefore the correct target for both, not
# `multiclass_from_probs()` (which assumes its input is already normalized
# and would silently double-apply softmax if handed raw logits).
nn_output_eqs <- function(
  linear_eqs,
  activation,
  mode,
  type = NULL,
  lvl = NULL,
  call = rlang::caller_env()
) {
  n_out <- length(linear_eqs)

  if (mode == "regression") {
    if (n_out != 1) {
      cli::cli_abort(
        "A regression network must have exactly one output unit, not {n_out}.",
        call = call
      )
    }
    if (!activation %in% c("linear", "identity")) {
      cli::cli_abort(
        c(
          "A regression network's final activation must be {.val linear} or
           {.val identity}, not {.val {activation}}.",
          i = "Bound outputs (e.g. a trailing sigmoid) are not regression
               outputs orbital can infer automatically; pass an explicit
               {.arg mode} if this is intentional."
        ),
        call = call
      )
    }
    return(stats::setNames(unname(linear_eqs), ".pred"))
  }

  if (n_out == 1) {
    if (!activation %in% c("sigmoid", "linear", "identity")) {
      cli::cli_abort(
        c(
          "A single-output-unit classification network's final activation
           must be {.val sigmoid}, {.val linear}, or {.val identity}, not
           {.val {activation}}.",
          i = "A single output unit is always treated as a binary
               classification logit and passed through a sigmoid, whether or
               not the source model applied one explicitly."
        ),
        call = call
      )
    }
    prob_eq <- nn_activation_expr(unname(linear_eqs), "sigmoid")
    return(binary_from_prob_first(prob_eq, type, lvl))
  }

  if (!activation %in% c("linear", "identity", "softmax")) {
    cli::cli_abort(
      c(
        "Activation {.val {activation}} is not supported as a final-layer
         activation for a {n_out}-unit classification output.",
        i = "Supported final-layer activations for two or more output units
             are {.val linear}/{.val identity} (raw per-class scores) and
             {.val softmax} (routed the same way, since softmax cannot be
             computed per neuron and the stored values are always the
             pre-softmax logits)."
      ),
      call = call
    )
  }

  multiclass_from_logits(unname(linear_eqs), type, lvl)
}

# Multi-output networks (issue #185): validates the `list(trunk = ..., heads =
# list(...))` shape `orbital.list()` requires, per the design doc's decision
# to require an explicit trunk/heads split rather than tracing an arbitrary
# `nn_module`'s `forward()` (out of scope; see the dev plan).
nn_check_trunk_heads <- function(x, call = rlang::caller_env()) {
  nms <- names(x)
  if (is.null(nms) || !identical(sort(nms), c("heads", "trunk"))) {
    cli::cli_abort(
      c(
        "A multi-output network must be a list with exactly two named
         elements, {.field trunk} and {.field heads}.",
        i = "Got names {.val {nms}}."
      ),
      call = call
    )
  }

  if (!inherits(x$trunk, "nn_sequential")) {
    cli::cli_abort(
      "{.field trunk} must be a {.cls nn_sequential}, not
       {.obj_type_friendly {x$trunk}}.",
      call = call
    )
  }

  heads <- x$heads
  head_names <- names(heads)
  if (
    !is.list(heads) ||
      length(heads) == 0 ||
      is.null(head_names) ||
      any(head_names == "") ||
      anyDuplicated(head_names) != 0
  ) {
    cli::cli_abort(
      "{.field heads} must be a non-empty list with unique names.",
      call = call
    )
  }

  is_seq <- vapply(heads, inherits, logical(1), "nn_sequential")
  if (!all(is_seq)) {
    cli::cli_abort(
      "Every element of {.field heads} must be a {.cls nn_sequential}, but
       {.val {head_names[!is_seq]}} {?is/are} not.",
      call = call
    )
  }
}

# `mode`/`type`/`lvl` for a multi-output network are each either `NULL` (every
# head falls back to its own default/inferred value, exactly as a
# single-output network would) or a list named by head, validated against the
# network's actual head names so a typo or a head added later fails loudly
# instead of silently falling back to the default for that head. Heads
# omitted from the list keep their own default/inferred value too — a caller
# only needs to override the heads that actually need it (e.g. supplying
# `lvl` only for the one head that's classification).
nn_multi_arg <- function(x, head_names, arg_name, call = rlang::caller_env()) {
  out <- stats::setNames(vector("list", length(head_names)), head_names)

  if (is.null(x)) {
    return(out)
  }

  nms <- names(x)
  if (is.null(nms) || any(nms == "")) {
    cli::cli_abort(
      "{.arg {arg_name}} must be a list named by head for a multi-output
       network, not {.obj_type_friendly {x}}.",
      call = call
    )
  }

  extra <- setdiff(nms, head_names)
  if (length(extra) > 0) {
    cli::cli_abort(
      c(
        "{.arg {arg_name}} has names not matching any head: {.val {extra}}.",
        i = "This network's heads are {.val {head_names}}."
      ),
      call = call
    )
  }

  out[nms] <- x
  out
}
