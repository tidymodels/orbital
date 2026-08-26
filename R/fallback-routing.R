# Adapts a tidypredict result into the sentinel-named equations that
# `set_pred_names()` expects.
#
# orbital's own methods attach those sentinels themselves; a tidypredict result
# carries none, so without this the prediction columns come out named after
# tidypredict's internals.
#
# What shape the result has cannot be recovered from the result itself, which is
# why it is asked for rather than sniffed. `LiblineaR` returns a single
# expression both for a probability and for an uncalibrated decision value, and
# cutting a decision value at 0.5 would give silently wrong classes for every
# row whose value falls between 0 and 0.5.
route_fallback <- function(res, x, mode, type, call = rlang::caller_env()) {
  if (mode != "classification") {
    return(res)
  }

  output <- tryCatch(
    tidypredict_output_type(x$fit),
    # A model tidypredict can fit but cannot describe. Refusing keeps the
    # pre-routing behaviour rather than guessing at the shape.
    tidypredict_no_metadata = function(cnd) abort_unsupported_output(x, call)
  )

  switch(
    output,
    prob = route_prob(res, x, type, call),
    decision = binary_from_decision(
      deparse_eq(res, x, call),
      type,
      x$lvl,
      call = call
    ),
    class = route_class(res, x, type, call),
    # A classification model whose fit is a plain number is `binary:hinge` and
    # friends; that is reported as "class", so reaching here means the mode and
    # the model disagree.
    numeric = abort_unsupported_output(x, call)
  )
}

# Wrapped rather than called through `tidypredict::` so that tests can mock it
# without reaching into another package's namespace. See `?local_mocked_bindings`.
tidypredict_output_type <- function(x) {
  tidypredict::tidypredict_output_type(x)
}

route_prob <- function(res, x, type, call) {
  lvl <- x$lvl

  abort_if_class_by_centroid(x, type, call)

  if (is.language(res)) {
    # Binary: one expression giving the probability of the second level.
    return(binary_from_prob(deparse1(res, control = "digits17"), type, lvl))
  }

  if (isFALSE(tidypredict::tidypredict_normalized(x$fit))) {
    cli::cli_abort(
      c(
        "Per-level values for this model do not sum to one.",
        i = "orbital does not yet normalize them."
      ),
      call = call
    )
  }

  prob_eqs <- order_prob_eqs(deparse_eqs(res), x, lvl, call)

  multiclass_from_probs(prob_eqs, type, lvl)
}

# tidypredict returns the per-level expressions in model order, which need not
# be the order parsnip recorded. When the fitted model did not retain its
# outcome levels the names are positional placeholders (`class_0`, `class_1`),
# so position is all there is to go on.
order_prob_eqs <- function(prob_eqs, x, lvl, call) {
  if (length(prob_eqs) != length(lvl)) {
    cli::cli_abort(
      "Model returned {length(prob_eqs)} expression{?s} for {length(lvl)}
       outcome level{?s}.",
      call = call
    )
  }

  model_levels <- tidypredict::tidypredict_outcome_levels(x$fit)

  if (is.null(model_levels)) {
    return(unname(prob_eqs))
  }

  if (!setequal(model_levels, lvl)) {
    cli::cli_abort(
      c(
        "Model's outcome levels do not match the ones {.pkg parsnip} recorded.",
        i = "Model: {.val {model_levels}}.",
        i = "Expected: {.val {lvl}}."
      ),
      call = call
    )
  }

  unname(stats::setNames(prob_eqs, model_levels)[lvl])
}

# mixOmics discriminant models assign a class by distance to the class centroid
# in the latent space rather than by taking the largest per-level value. The two
# rules disagree on a fifth of the rows of `iris`, so unlike every other
# probability backend the class label cannot be derived from the per-level
# expressions. The values themselves are exact, so only `type = "class"` goes.
abort_if_class_by_centroid <- function(x, type, call) {
  if (!"class" %in% type || !inherits(x$fit, "DA")) {
    return(invisible())
  }

  cli::cli_abort(
    c(
      "{.val class} predictions are not available for this model.",
      i = "It assigns a class by distance to the class centroid, which the
           per-level values do not determine.",
      i = "Use {.code type = \"prob\"} instead."
    ),
    call = call
  )
}

# Backends that predict a class label and nothing else: there is no probability
# to return and none can be derived, so asking for one is refused rather than
# answered with a fabricated number.
route_class <- function(res, x, type, call) {
  if ("prob" %in% type) {
    cli::cli_abort(
      c(
        "{.val prob} predictions are not available for this model.",
        i = "It predicts a class directly, with no probability behind it.",
        i = "Use {.code type = \"class\"} instead."
      ),
      call = call
    )
  }

  c(orbital_tmp_class_name = deparse_eq(res, x, call))
}

deparse_eq <- function(res, x, call) {
  if (!is.language(res)) {
    cli::cli_abort(
      "Expected a single expression, not {.obj_type_friendly {res}}.",
      call = call
    )
  }

  deparse1(res, control = "digits17")
}

abort_unsupported_output <- function(x, call) {
  cls <- class(x)
  cls <- setdiff(cls, "model_fit")
  cls <- gsub("^_", "", cls)

  cli::cli_abort(
    c(
      "Classification output for a model of class {.cls {cls}} is not yet
       supported.",
      i = "The model itself is supported for {.val regression} mode."
    ),
    call = call
  )
}
