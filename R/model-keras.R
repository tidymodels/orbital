# Bare keras3 Sequential support (issue #149, milestone 3b). Unlike torch/
# brulee (milestone 2), there is only one class here: `parsnip::mlp(engine =
# "keras3")`'s fitted object *is* a `keras.src.models.sequential.Sequential`,
# the exact same class a user gets from calling `keras3::keras_model_sequential()`
# directly (confirmed by the milestone's discovery task). So this single
# method is both the bare entry point and what `orbital.model_fit()`
# dispatches into, distinguished by `.from_parsnip` the same way
# `orbital.brulee_mlp()` distinguishes a direct call from a parsnip one.

# keras activation config strings with no per-layer parameters to read: a
# `Dense` layer's `activation` is always a plain string (or a bare function
# reference that serializes to the same string), never an object carrying
# custom arguments the way torch's `nn_leaky_relu`/`nn_elu` modules do, so the
# non-default-parameter activations below use keras's own defaults rather
# than a value read off the fitted layer.
keras_simple_activations <- c(
  relu = "relu",
  sigmoid = "sigmoid",
  tanh = "tanh",
  linear = "linear",
  softmax = "softmax",
  # keras's default `approximate = FALSE` is the exact erf-based gelu;
  # `nn_activation_expr()` always applies the tanh-approximation form
  # regardless (no SQL-translatable form of `erf` exists), the same
  # deliberate, documented substitution as for torch's `nn_gelu()`.
  gelu = "gelu"
)

# `keras3::activation_leaky_relu()`'s default `negative_slope` is 0.2 (torch's
# `nn_leaky_relu()` default is 0.01); `activation_elu()`'s default `alpha` is
# 1, matching torch. Neither can be overridden through the string form of
# `activation =`, so a custom value never reaches `get_config()` in the first
# place.
keras_param_activations <- list(
  leaky_relu = list(negative_slope = 0.2),
  elu = list(alpha = 1)
)

keras_activation_strings <- c(
  names(keras_simple_activations),
  names(keras_param_activations)
)

# Walks a keras3 `Sequential`'s `$layers` into `list(list(weight, bias,
# activation, params), ...)`, one entry per `Dense` layer. `Dropout` is a
# no-op at eval time and is skipped, mirroring `nn_sequential_layers()`.
keras_sequential_layers <- function(layers, call = rlang::caller_env()) {
  out <- list()

  for (layer in layers) {
    cls <- class(layer)[1]

    if (cls == "keras.src.layers.core.dense.Dense") {
      weights <- layer$get_weights()
      # keras stores the kernel as `in x out`, the transpose of the `out x
      # in` orientation `build_linear_pred()`/`nn_layer_exprs()` want (torch's
      # native orientation, confirmed by the milestone's discovery spike).
      weight <- t(as.matrix(weights[[1]]))
      bias <- if (length(weights) > 1) {
        as.numeric(weights[[2]])
      } else {
        rep(0, nrow(weight))
      }
      activation <- layer$get_config()$activation

      if (!activation %in% keras_activation_strings) {
        cli::cli_abort(
          c(
            "Activation {.val {activation}} is not supported.",
            i = "Supported activations are: {.val {keras_activation_strings}}."
          ),
          call = call
        )
      }

      out[[length(out) + 1]] <- list(
        weight = weight,
        bias = bias,
        activation = activation,
        params = keras_param_activations[[activation]] %||% list()
      )
      next
    }

    if (cls == "keras.src.layers.regularization.dropout.Dropout") {
      next
    }

    cli::cli_abort(
      c(
        "Layer {.cls {cls}} is not supported.",
        i = "Supported layers are {.cls Dense} and {.cls Dropout}."
      ),
      call = call
    )
  }

  for (i in seq_along(out)) {
    if (out[[i]]$activation == "softmax" && i != length(out)) {
      cli::cli_abort(
        c(
          "{.val softmax} is only supported as the final layer's activation.",
          i = "Softmax cannot be computed per neuron, so it can't be used on
               a hidden layer."
        ),
        call = call
      )
    }
  }

  out
}

# `parsnip::mlp(engine = "keras3")`'s fitted object carries no blueprint of
# its own (unlike brulee's `x$dims$features`); the predictor names live on
# the surrounding `model_fit` object's legacy `preproc` bookkeeping instead,
# shaped differently depending on which interface `fit()`/`fit_xy()` used.
keras_predictor_names <- function(x, call = rlang::caller_env()) {
  if (!is.null(x$preproc$x_names)) {
    return(x$preproc$x_names)
  }
  term_labels <- attr(x$preproc$terms, "term.labels")
  if (!is.null(term_labels)) {
    return(term_labels)
  }

  cli::cli_abort(
    "Could not determine the model's predictor names.",
    call = call
  )
}

#' @export
orbital.keras.src.models.sequential.Sequential <- function(
  x,
  ...,
  input_names = NULL,
  mode = NULL,
  type = NULL,
  lvl = NULL,
  prefix = ".pred",
  output_layer = NULL,
  .from_parsnip = FALSE
) {
  if (is.null(input_names)) {
    cli::cli_abort(
      c(
        "{.arg input_names} is required for bare keras3 {.cls Sequential}
         models.",
        i = "A {.cls Sequential} model's input is an anonymous fixed-width
             vector with no per-feature names stored anywhere in its config,
             so orbital cannot infer the model's input feature names the way
             it can for most other model types."
      )
    )
  }

  layers <- keras_sequential_layers(x$layers)

  if (length(layers) == 0) {
    cli::cli_abort("{.arg x} contains no {.cls Dense} layers.")
  }

  nn_check_input_names(input_names, ncol(layers[[1]]$weight))

  final_activation <- layers[[length(layers)]]$activation
  n_out <- nrow(layers[[length(layers)]]$weight)

  if (is.null(mode)) {
    mode <- nn_infer_mode(n_out, final_activation)
  }
  mode <- rlang::arg_match(mode, c("classification", "regression"))
  # `orbital.model_fit()` already validated the user-supplied `type` against
  # `mode` before dispatching here, then unconditionally defaulted it to
  # `"class"` (even for a regression model, where it's simply never
  # consulted downstream); re-validating that already-defaulted value here
  # would wrongly reject a `"regression"` mode's `type`.
  if (!.from_parsnip) {
    check_type(type, mode)
  }
  type <- default_type(type)

  if (mode == "classification") {
    nn_check_lvl(lvl, n_out)
    lvl <- lvl %||% nn_default_lvl(n_out)
  }

  forward <- nn_forward_eqs(layers, input_names)
  out_eqs <- nn_output_eqs(
    forward$linear_eqs,
    final_activation,
    mode,
    type,
    lvl
  )
  layer_names <- nn_output_layer_names(
    forward$hidden_eqs,
    output_layer,
    length(layers)
  )

  res <- c(forward$hidden_eqs, out_eqs)

  if (.from_parsnip) {
    # Reached through `orbital.model_fit()`, which does its own
    # `set_pred_names()`/`new_orbital_class()` pass afterward (see
    # `orbital.brulee_mlp()` for the same pattern and why the `output_layer`
    # names have to travel back as an attribute rather than through
    # `pred_names` directly).
    if (!is.null(layer_names)) {
      attr(res, "orbital_output_layer_names") <- layer_names
    }
    return(res)
  }

  res <- set_pred_names(res, lvl, mode, type, prefix)
  if (!is.null(layer_names)) {
    attr(res, "pred_names") <- c(attr(res, "pred_names"), layer_names)
  }

  new_orbital_class(res)
}
