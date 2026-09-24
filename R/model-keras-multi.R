# Multi-output networks (issue #185), keras3 side. Unlike torch, keras's
# functional API already exposes the model's DAG directly in
# `x$get_config()`: each non-input layer's `inbound_nodes[[1]]$args[[1]]$
# config$keras_history` names its upstream layer, and `cfg$output_layers`
# lists which layer(s) are the model's outputs (confirmed by spike, see the
# design doc's "Multi-output networks" section). So, unlike
# `orbital.list()` (torch side), there's no separate user-facing trunk/heads
# shape to validate here: the trunk/heads split is inferred from the graph
# itself, by finding the longest run of layers shared by every output's
# ancestor path back to the input.

# Extracts one non-input layer's parent layer name from its config entry.
# Only a single inbound call with a single tensor argument is supported (a
# plain chain of one-input-one-output layers); a layer invoked more than once,
# or one that merges multiple tensors (e.g. `layer_concatenate()`), has no
# meaning for the trunk/heads shape this package supports.
keras_layer_parent_name <- function(entry, call) {
  inbound <- entry$inbound_nodes
  if (length(inbound) == 0) {
    return(NULL)
  }
  if (length(inbound) != 1) {
    cli::cli_abort(
      "Layer {.val {entry$name}} is called more than once in the model
       graph, which is not supported.",
      call = call
    )
  }

  args <- inbound[[1]]$args
  if (length(args) != 1) {
    cli::cli_abort(
      "Layer {.val {entry$name}} takes more than one input tensor (e.g. a
       merge layer such as {.fn layer_concatenate}), which is not supported.",
      call = call
    )
  }

  history <- args[[1]]$config$keras_history
  if (is.null(history)) {
    cli::cli_abort(
      "Could not determine the upstream layer for {.val {entry$name}}.",
      call = call
    )
  }
  history[[1]]
}

# Walks a functional model's config into `parent_of` (a named character
# vector, non-input layer name -> its single parent layer name) and the name
# of the model's single input layer.
keras_functional_graph <- function(x, call = rlang::caller_env()) {
  cfg <- x$get_config()

  # A single input serializes as one flat `(name, node_idx, tensor_idx)`
  # tuple; two or more serialize as a list of such tuples. Normalize to the
  # latter shape before counting.
  input_layers <- cfg$input_layers
  if (is.character(input_layers[[1]])) {
    input_layers <- list(input_layers)
  }
  if (length(input_layers) != 1) {
    cli::cli_abort(
      "Only functional models with a single input are supported, not
       {length(input_layers)}.",
      call = call
    )
  }
  input_name <- input_layers[[1]][[1]]

  cfg_by_name <- stats::setNames(
    cfg$layers,
    vapply(cfg$layers, function(l) l$name, character(1))
  )

  parent_of <- vapply(
    cfg_by_name,
    function(entry) keras_layer_parent_name(entry, call) %||% NA_character_,
    character(1)
  )

  list(
    parent_of = parent_of[!is.na(parent_of)],
    input_name = input_name,
    output_layers = cfg$output_layers
  )
}

# The ordered chain of layer names from just after the input layer through to
# (and including) `name`, walking backward via `parent_of` one step at a
# time. Bounded by the total number of layers so a malformed/cyclic graph
# errors instead of looping forever (shouldn't be reachable through keras's
# own functional API, but cheap to guard).
keras_ancestor_path <- function(name, parent_of, input_name, call) {
  path <- character(0)
  steps <- 0L
  max_steps <- length(parent_of) + 1L

  while (!identical(name, input_name)) {
    steps <- steps + 1L
    if (steps > max_steps) {
      cli::cli_abort(
        "Could not resolve the model graph to the input layer.",
        call = call
      )
    }
    path <- c(name, path)
    name <- parent_of[[name]]
    if (is.null(name) || is.na(name)) {
      cli::cli_abort(
        "Could not resolve the model graph to the input layer.",
        call = call
      )
    }
  }

  path
}

#' @export
orbital.keras.src.models.functional.Functional <- function(
  x,
  ...,
  input_names = NULL,
  mode = NULL,
  type = NULL,
  lvl = NULL,
  prefix = ".pred",
  output_layer = NULL
) {
  if (is.null(input_names)) {
    cli::cli_abort(
      c(
        "{.arg input_names} is required for bare keras3 functional models.",
        i = "A functional model's input is an anonymous fixed-width vector
             with no per-feature names stored anywhere in its config, so
             orbital cannot infer the model's input feature names the way it
             can for most other model types."
      )
    )
  }
  if (!is.null(output_layer)) {
    cli::cli_abort(
      "{.arg output_layer} is not supported for multi-output networks."
    )
  }

  graph <- keras_functional_graph(x)
  output_layers <- graph$output_layers
  # A single output serializes as one flat `(name, node_idx, tensor_idx)`
  # tuple; two or more serialize as a list of such tuples (see
  # `keras_functional_graph()`'s identical normalization for `input_layers`).
  if (is.character(output_layers[[1]])) {
    output_layers <- list(output_layers)
  }
  if (length(output_layers) < 2) {
    cli::cli_abort(
      "{.arg x} has a single output; multi-output support only applies to
       functional models with two or more outputs."
    )
  }
  terminal_names <- vapply(output_layers, function(o) o[[1]], character(1))
  head_names <- names(output_layers)
  if (is.null(head_names) || any(head_names == "")) {
    head_names <- terminal_names
  }

  layer_objs <- stats::setNames(
    x$layers,
    vapply(x$layers, function(l) l$name, character(1))
  )

  paths <- lapply(
    terminal_names,
    keras_ancestor_path,
    parent_of = graph$parent_of,
    input_name = graph$input_name,
    call = rlang::caller_env()
  )

  max_trunk_len <- max(min(lengths(paths)) - 1L, 0L)
  trunk_len <- 0L
  if (max_trunk_len > 0) {
    first_path <- paths[[1]]
    while (
      trunk_len < max_trunk_len &&
        all(
          vapply(paths, `[[`, character(1), trunk_len + 1L) ==
            first_path[trunk_len + 1L]
        )
    ) {
      trunk_len <- trunk_len + 1L
    }
  }
  trunk_names <- if (trunk_len > 0) {
    paths[[1]][seq_len(trunk_len)]
  } else {
    character(0)
  }

  trunk_layers <- keras_sequential_layers(layer_objs[trunk_names])
  nn_check_input_names(input_names, x$inputs[[1]]$shape[[2]])

  trunk_forward <- nn_forward_eqs(
    trunk_layers,
    input_names,
    prefix = "orbital_nn_trunk",
    activate_final = TRUE
  )

  mode_list <- nn_multi_arg(mode, head_names, "mode")
  type_list <- nn_multi_arg(type, head_names, "type")
  lvl_list <- nn_multi_arg(lvl, head_names, "lvl")

  res <- trunk_forward$hidden_eqs
  pred_names <- character(0)

  for (i in seq_along(head_names)) {
    head_name <- head_names[[i]]
    # `trunk_len` is always strictly less than every path's own length (see
    # `max_trunk_len` above, reserved to `min(lengths(paths)) - 1`), so this
    # always leaves at least one layer of the head's own.
    head_path <- if (trunk_len > 0) {
      paths[[i]][-seq_len(trunk_len)]
    } else {
      paths[[i]]
    }

    head_layers <- keras_sequential_layers(layer_objs[head_path])
    if (length(head_layers) == 0) {
      cli::cli_abort(
        "Head {.val {head_name}} contains no {.cls Dense} layers."
      )
    }

    final_activation <- head_layers[[length(head_layers)]]$activation
    n_out <- nrow(head_layers[[length(head_layers)]]$weight)

    head_mode <- mode_list[[head_name]] %||%
      nn_infer_mode(n_out, final_activation)
    head_mode <- rlang::arg_match(head_mode, c("classification", "regression"))
    check_type(type_list[[head_name]], head_mode)
    head_type <- default_type(type_list[[head_name]])

    head_lvl <- lvl_list[[head_name]]
    if (head_mode == "classification") {
      nn_check_lvl(head_lvl, n_out)
      head_lvl <- head_lvl %||% nn_default_lvl(n_out)
    }

    head_forward <- nn_forward_eqs(
      head_layers,
      trunk_forward$names,
      prefix = sprintf("orbital_nn_%s", head_name)
    )
    head_out_eqs <- nn_output_eqs(
      head_forward$linear_eqs,
      final_activation,
      head_mode,
      head_type,
      head_lvl
    )

    head_prefix <- paste0(prefix, "_", head_name)
    head_res <- c(head_forward$hidden_eqs, head_out_eqs)
    head_res <- set_pred_names(
      head_res,
      head_lvl,
      head_mode,
      head_type,
      head_prefix
    )

    res <- c(res, head_res)
    pred_names <- c(pred_names, attr(head_res, "pred_names"))
  }

  attr(res, "pred_names") <- pred_names
  new_orbital_class(res)
}
