# Multi-output torch networks (issue #185, milestone 5). A shared trunk
# feeding two or more separate output heads is a branching graph, not a
# linear chain, so it can't be walked the way `nn_sequential_layers()` walks
# a bare `nn_sequential`'s `children` (that mechanism is inherently
# single-chain). Per the design doc, this requires the network as an explicit
# `list(trunk = ..., heads = list(...))`, each a plain `nn_sequential`, rather
# than tracing an arbitrary `nn_module`'s `forward()` (out of scope; would
# need `torch::jit_trace()`, a materially larger project).
#
# This reuses `nn_sequential_layers()`/`nn_forward_eqs()`/`nn_output_eqs()`
# unchanged: walk the trunk once with every layer activated (its output feeds
# each head as real values, not logits awaiting `nn_output_eqs()` routing),
# then walk each head once starting from the trunk's output column names,
# namespacing each walk's generated column names by trunk/head so they can
# never collide.

#' @export
orbital.list <- function(
  x,
  ...,
  input_names,
  mode = NULL,
  type = NULL,
  lvl = NULL,
  prefix = ".pred",
  output_layer = NULL
) {
  nn_check_trunk_heads(x)

  if (missing(input_names)) {
    cli::cli_abort(
      c(
        "{.arg input_names} is required for multi-output networks.",
        i = "Torch tensors are positional and carry no column names, so
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

  trunk_layers <- nn_sequential_layers(x$trunk$children)
  if (length(trunk_layers) == 0) {
    cli::cli_abort("{.field trunk} contains no {.cls nn_linear} layers.")
  }
  nn_check_input_names(input_names, ncol(trunk_layers[[1]]$weight))

  trunk_forward <- nn_forward_eqs(
    trunk_layers,
    input_names,
    prefix = "orbital_nn_trunk",
    activate_final = TRUE
  )

  head_names <- names(x$heads)
  mode_list <- nn_multi_arg(mode, head_names, "mode")
  type_list <- nn_multi_arg(type, head_names, "type")
  lvl_list <- nn_multi_arg(lvl, head_names, "lvl")

  res <- trunk_forward$hidden_eqs
  pred_names <- character(0)

  for (head_name in head_names) {
    head_layers <- nn_sequential_layers(x$heads[[head_name]]$children)
    if (length(head_layers) == 0) {
      cli::cli_abort(
        "Head {.val {head_name}} contains no {.cls nn_linear} layers."
      )
    }
    nn_check_input_names(
      trunk_forward$names,
      ncol(head_layers[[1]]$weight)
    )

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
