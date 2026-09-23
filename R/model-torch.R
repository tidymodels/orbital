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

# Normalization modules (milestone 4, issue #149): attach to the immediately
# preceding `nn_linear` layer as its `$norm`, the same way an activation
# module attaches as its `$activation`, since `nn_layer_exprs()` wants both
# folded into one layer entry rather than as separate modules in the walk.
torch_norm_modules <- c("nn_batch_norm1d", "nn_layer_norm")

# `nn_batch_norm1d`'s eval-time transform is a fixed per-channel affine read
# off its own stored running statistics (`running_mean`/`running_var`) and,
# if `affine = TRUE`, its learned `weight`/`bias` (gamma/beta); `affine =
# FALSE` means no learned scale/shift, i.e. gamma = 1, beta = 0.
# `track_running_stats = FALSE` means eval mode still normalizes by each
# batch's own statistics rather than fixed ones, which orbital has no batch
# to compute over and so can't reproduce as a static expression.
torch_batch_norm_norm <- function(child, call) {
  if (isFALSE(child$track_running_stats)) {
    cli::cli_abort(
      c(
        "{.cls nn_batch_norm1d} with {.code track_running_stats = FALSE} is
         not supported.",
        i = "Without stored running statistics, its evaluation-time output
             depends on each prediction batch's own statistics, which
             orbital cannot reproduce as a fixed per-row expression."
      ),
      call = call
    )
  }

  n <- length(child$running_mean)
  list(
    type = "batch_norm",
    running_mean = as.numeric(child$running_mean),
    running_var = as.numeric(child$running_var),
    gamma = if (isTRUE(child$affine)) as.numeric(child$weight) else rep(1, n),
    beta = if (isTRUE(child$affine)) as.numeric(child$bias) else rep(0, n),
    eps = as.numeric(child$eps)
  )
}

# `nn_layer_norm`'s eval-time transform normalizes over the dimensions given
# by `normalized_shape`; only the single-dimension case matching the
# preceding linear layer's full output width is supported (normalizing over
# a subset, or over more dimensions than exist here, has no meaning for a
# feed-forward MLP's per-row neuron vector).
torch_layer_norm_norm <- function(child, n_in, call) {
  shape <- as.integer(unlist(child$normalized_shape))
  if (length(shape) != 1 || shape != n_in) {
    cli::cli_abort(
      c(
        "{.cls nn_layer_norm} is only supported when normalizing over
         exactly the preceding layer's {n_in} output unit{?s}.",
        i = "Got {.code normalized_shape = {shape}}."
      ),
      call = call
    )
  }

  list(
    type = "layer_norm",
    gamma = if (!is.null(child$weight)) {
      as.numeric(child$weight)
    } else {
      rep(1, n_in)
    },
    beta = if (!is.null(child$bias)) as.numeric(child$bias) else rep(0, n_in),
    eps = as.numeric(child$eps)
  )
}

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

    if (cls %in% torch_norm_modules) {
      if (length(layers) == 0) {
        cli::cli_abort(
          "A {.cls {cls}} module cannot be the first module in a
           {.cls nn_sequential}.",
          call = call
        )
      }
      last <- layers[[length(layers)]]
      if (!is.null(last$norm)) {
        cli::cli_abort(
          "A {.cls nn_linear} layer can only be followed by one
           normalization module, but this one has both {.cls {last$norm$cls}}
           and {.cls {cls}}.",
          call = call
        )
      }
      if (last$activation != "linear") {
        cli::cli_abort(
          c(
            "{.cls {cls}} must come before the activation module in each
             {.cls nn_linear} block.",
            i = "Got an activation module already applied to this layer
                 before {.cls {cls}}."
          ),
          call = call
        )
      }

      norm <- if (cls == "nn_batch_norm1d") {
        torch_batch_norm_norm(child, call)
      } else {
        torch_layer_norm_norm(child, nrow(last$weight), call)
      }
      norm$cls <- cls
      layers[[length(layers)]]$norm <- norm
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
        i = "Supported modules are {.cls nn_linear}, {.cls nn_dropout}, the
             activation modules {.cls {torch_activation_modules}}, and the
             normalization modules {.cls {torch_norm_modules}}."
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
  prefix = ".pred",
  output_layer = NULL
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
  res <- set_pred_names(res, lvl, mode, type, prefix)
  if (!is.null(layer_names)) {
    attr(res, "pred_names") <- c(attr(res, "pred_names"), layer_names)
  }

  new_orbital_class(res)
}
