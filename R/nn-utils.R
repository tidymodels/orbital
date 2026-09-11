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
# Returns `list(eqs, names)`: `eqs` is a named character vector, one
# expression per output neuron; `names` is `names(eqs)`, handed back so the
# caller can thread it in as the next layer's `input_names`.
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
  batch_size = 50
) {
  n_out <- nrow(weight)
  width <- nchar(as.character(n_out))
  out_names <- sprintf(paste0(layer_prefix, "_%0", width, "d"), seq_len(n_out))

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
      exprs[[out_names[i]]] <- nn_activation_expr(lin, activation, params)
    }
    barrier <- out_names[idx[length(idx)]]
  }

  list(eqs = exprs, names = out_names)
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
