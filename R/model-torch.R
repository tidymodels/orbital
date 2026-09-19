# Bare torch::nn_sequential() support (issue #149, milestone 2a). brulee's
# `mlp()` engine reuses `nn_sequential_layers()` unchanged (milestone 2b); this
# file only covers the bare-object entry point.

# Activation modules with no constructor parameters map straight to their
# activation name.
torch_simple_activations <- c(
  nn_relu = "relu",
  nn_sigmoid = "sigmoid",
  nn_tanh = "tanh",
  nn_identity = "identity",
  nn_gelu = "gelu"
)

# Activation modules whose constructor parameters must be read off the
# fitted layer.
torch_param_activations <- list(
  nn_leaky_relu = \(child) list(negative_slope = child$negative_slope),
  nn_elu = \(child) list(alpha = child$alpha)
)

# `nn_softmax` is handled separately from the two lookups above: unlike
# every other activation it can't be computed per neuron (it needs the whole
# layer to normalize), so it's only valid as the final layer's activation
# (enforced after `nn_sequential_layers()`'s main loop), and its `dim` must
# actually be over the per-example class scores rather than, say, the batch
# dimension.
torch_activation_modules <- c(
  names(torch_simple_activations),
  names(torch_param_activations),
  "nn_softmax"
)

# Walks a torch `nn_sequential`'s children into `list(list(weight, bias,
# activation, params), ...)`, one entry per `nn_linear` layer. An activation
# module attaches to the immediately preceding `nn_linear` layer rather than
# becoming its own entry, since `nn_layer_exprs()` wants one activation per
# layer, not per module. `nn_dropout` is a no-op at eval time and is skipped
# rather than erroring on it.
nn_sequential_layers <- function(children, call = rlang::caller_env()) {
  layers <- list()

  for (child in children) {
    cls <- class(child)[1]

    if (cls == "nn_linear") {
      weight <- as.matrix(child$parameters$weight)
      bias <- child$parameters$bias
      # `nn_linear(bias = FALSE)` has no bias parameter at all; treat it as
      # an all-zero bias rather than letting `as.numeric(NULL)` silently
      # become `numeric(0)` and crash deep inside `build_linear_pred()`.
      bias <- if (is.null(bias)) rep(0, nrow(weight)) else as.numeric(bias)
      layers[[length(layers) + 1]] <- list(
        weight = weight,
        bias = bias,
        activation = "linear",
        params = list()
      )
      next
    }

    if (cls == "nn_dropout") {
      next
    }

    if (cls %in% torch_activation_modules) {
      if (length(layers) == 0) {
        cli::cli_abort(
          "A {.cls {cls}} module cannot be the first module in a
           {.cls nn_sequential}.",
          call = call
        )
      }

      if (cls == "nn_softmax") {
        if (!is.null(child$dim) && !child$dim %in% c(-1, 2)) {
          cli::cli_abort(
            c(
              "{.cls nn_softmax} is only supported when normalizing over the
               last dimension (the per-example class scores).",
              i = "Got {.code dim = {child$dim}}; only {.code dim = 2} or
                   {.code dim = -1} are supported."
            ),
            call = call
          )
        }
        layers[[length(layers)]]$activation <- "softmax"
        layers[[length(layers)]]$params <- list()
      } else if (cls %in% names(torch_simple_activations)) {
        layers[[length(layers)]]$activation <- torch_simple_activations[[cls]]
        layers[[length(layers)]]$params <- list()
      } else {
        layers[[length(layers)]]$activation <- sub("^nn_", "", cls)
        layers[[length(layers)]]$params <- torch_param_activations[[cls]](child)
      }
      next
    }

    cli::cli_abort(
      c(
        "Module {.cls {cls}} is not supported.",
        i = "Supported modules are {.cls nn_linear}, {.cls nn_dropout}, and
             the activation modules {.cls {torch_activation_modules}}."
      ),
      call = call
    )
  }

  # Softmax cannot be computed per neuron (it needs the whole layer's values
  # at once to normalize), so `nn_layer_exprs()` never actually materializes
  # it; it's only meaningful as the final layer's activation, where
  # `nn_output_eqs()` routes it through `multiclass_from_logits()` directly.
  for (i in seq_along(layers)) {
    if (layers[[i]]$activation == "softmax" && i != length(layers)) {
      cli::cli_abort(
        c(
          "{.cls nn_softmax} is only supported as the final layer's
           activation.",
          i = "Softmax cannot be computed per neuron, so it can't be used on
               a hidden layer."
        ),
        call = call
      )
    }
  }

  layers
}

#' @export
orbital.nn_sequential <- function(
  x,
  ...,
  input_names,
  mode = NULL,
  type = NULL,
  lvl = NULL,
  prefix = ".pred"
) {
  if (missing(input_names)) {
    cli::cli_abort(
      c(
        "{.arg input_names} is required for bare {.cls nn_sequential} models.",
        i = "Torch tensors are positional and carry no column names, so
             orbital cannot infer the model's input feature names the way it
             can for most other model types."
      )
    )
  }

  layers <- nn_sequential_layers(x$children)

  if (length(layers) == 0) {
    cli::cli_abort("{.arg x} contains no {.cls nn_linear} layers.")
  }

  nn_check_input_names(input_names, ncol(layers[[1]]$weight))

  final_activation <- layers[[length(layers)]]$activation
  n_out <- nrow(layers[[length(layers)]]$weight)

  if (is.null(mode)) {
    mode <- nn_infer_mode(n_out, final_activation)
  }
  mode <- rlang::arg_match(mode, c("classification", "regression"))
  check_type(type, mode)
  type <- default_type(type)

  if (mode == "classification") {
    nn_check_lvl(lvl, n_out)
    lvl <- lvl %||% nn_default_lvl(n_out)
  }

  hidden_eqs <- character(0)
  linear_eqs <- NULL
  names_in <- input_names

  for (i in seq_along(layers)) {
    layer <- layers[[i]]
    is_last <- i == length(layers)

    layer_res <- nn_layer_exprs(
      layer$weight,
      layer$bias,
      names_in,
      activation = if (is_last) "linear" else layer$activation,
      layer_prefix = sprintf("orbital_nn_L%d", i),
      params = if (is_last) list() else layer$params
    )

    if (is_last) {
      linear_eqs <- layer_res$eqs
    } else {
      hidden_eqs <- c(hidden_eqs, layer_res$eqs)
    }
    names_in <- layer_res$names
  }

  out_eqs <- nn_output_eqs(linear_eqs, final_activation, mode, type, lvl)

  res <- c(hidden_eqs, out_eqs)
  res <- set_pred_names(res, lvl, mode, type, prefix)

  new_orbital_class(res)
}
