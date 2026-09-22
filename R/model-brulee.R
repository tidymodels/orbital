# parsnip::mlp(engine = "brulee") support (issue #149, milestone 2b). A
# `brulee_mlp` fit is bookkeeping wrapped around a torch `nn_sequential`
# (`object$model_obj` is a serialized, empty-weights module; `object$estimates`
# holds the weights per epoch); this file only reconstructs that module and
# reuses `nn_sequential_layers()`/`nn_forward_eqs()` from `R/model-torch.R` and
# `R/nn-utils.R` unchanged.

# `brulee:::revive_model()` and the `epoch + 1` indexing into `object$estimates`
# below are undocumented internals, not brulee's public API. Confirmed by
# reading `brulee:::predict_brulee_mlp_raw()`'s own source: it indexes
# `model$estimates[[epoch + 1]]`, i.e. `object$best_epoch` is 0-based (epoch 0
# is the untrained initial state, stored as `estimates[[1]]`) while R's
# `estimates` list is 1-based. Read this straight off the epoch actually
# requested (`best_epoch` unless the caller means something else by `epoch`),
# not assumed, since a future brulee release changing this indexing would
# otherwise silently pick the wrong epoch's weights rather than error.
brulee_revive_mlp <- function(x, epoch = x$best_epoch) {
  module <- brulee:::revive_model(x$model_obj)
  module$load_state_dict(x$estimates[[epoch + 1]])
  module$eval()
  module
}

# brulee's own `predict_brulee_mlp_numeric()` un-scales regression output as
# `predictions * y_stats$sd + y_stats$mean`; applied here to the generated
# expression instead of to a live tensor.
brulee_unscale_expr <- function(eq, y_stats) {
  glue::glue(
    "({eq}) * {format_numeric(y_stats$sd)} + {format_numeric(y_stats$mean)}"
  )
}

#' @export
orbital.brulee_mlp <- function(
  x,
  ...,
  mode = c("classification", "regression"),
  type = NULL,
  lvl = NULL,
  output_layer = NULL,
  .from_parsnip = FALSE
) {
  check_bare_fit(x, .from_parsnip)
  mode <- rlang::arg_match(mode)
  type <- default_type(type)

  if (mode == "classification" && is.null(lvl)) {
    lvl <- x$dims$levels
  }

  module <- brulee_revive_mlp(x)
  layers <- nn_sequential_layers(module$model$children)
  final_activation <- layers[[length(layers)]]$activation

  forward <- nn_forward_eqs(layers, x$dims$features)
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

  if (mode == "regression") {
    out_eqs[[1]] <- brulee_unscale_expr(out_eqs[[1]], x$y_stats)
  }

  res <- c(forward$hidden_eqs, out_eqs)
  # `orbital.brulee_mlp()` is only ever reached through `orbital.model_fit()`
  # dispatching on `x$fit` (`check_bare_fit()` above refuses a direct bare
  # call), so it must return a raw named-expression vector for
  # `orbital.model_fit()` to name and wrap, not call `set_pred_names()` or
  # `new_orbital_class()` itself. The requested `output_layer` names have
  # nowhere else to travel back to the caller, so they're smuggled through as
  # an attribute `orbital.model_fit()` knows to look for and merge into
  # `pred_names` after its own naming pass.
  if (!is.null(layer_names)) {
    attr(res, "orbital_output_layer_names") <- layer_names
  }
  res
}
