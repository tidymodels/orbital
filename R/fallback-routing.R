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
      decision_positive_level(x, call),
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
    # Binary: one expression giving the probability of a single level, which is
    # the model's second level rather than necessarily parsnip's.
    eq <- deparse_exact(res)
    rule <- prob_class_rule(x)

    if (identical(binary_positive_level(x, lvl), lvl[2])) {
      return(binary_from_prob(eq, type, lvl, rule$cut, rule$op))
    }

    return(binary_from_prob_first(eq, type, lvl, rule$cut, rule$op))
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

# Which level the single binary probability expression is for.
#
# Every backend but h2o orders its classes the way the outcome's factor levels
# are ordered, making this `lvl[2]`. h2o sorts its own domain and keeps that
# order regardless, so a model fitted on reversed levels still returns the
# probability of what parsnip calls the first level. Taking it for the second
# would swap both probability columns and invert the class.
binary_positive_level <- function(x, lvl) {
  model_levels <- tryCatch(
    tidypredict::tidypredict_outcome_levels(x$fit),
    error = function(e) NULL
  )

  if (length(model_levels) != 2 || !setequal(model_levels, lvl)) {
    return(lvl[2])
  }

  model_levels[2]
}

# Which outcome level a positive decision value means.
#
# LiblineaR orients its decision function toward the first entry of
# `ClassNames`, which is the model's own class order and is independent of how
# the outcome's factor levels are ordered. Reversing the levels of the outcome
# therefore flips which level a positive value means, so this cannot be read off
# `lvl`. tidypredict has no accessor for it yet, hence reaching into the fit.
decision_positive_level <- function(x, call) {
  class_names <- as.character(x$fit$ClassNames)

  if (length(class_names) != 2 || !all(class_names %in% x$lvl)) {
    cli::cli_abort(
      c(
        "Cannot tell which outcome level a positive decision value means.",
        i = "The model does not record its class order in a form orbital
             recognizes."
      ),
      call = call
    )
  }

  class_names[1]
}

# The rule turning the binary probability into a class: the threshold, and the
# comparison made against it.
#
# `0.5` and `>` for every model that picks the larger of the two probabilities.
# Two do not.
#
# h2o chooses a threshold maximizing F1 on the training data and applies that
# instead of 0.5, so its own labels can disagree with its own probabilities
# across a wide band. On `iris` the F1 threshold came out at 0.90, putting a 0.5
# cut at odds with the model on half the rows. It compares with `>=`, and since
# the threshold it picks is an observed probability rather than an arbitrary
# number, rows landing exactly on it are common rather than a curiosity.
#
# kernlab classifies by the sign of the decision function and calibrates the
# probabilities separately with Platt scaling, so the two rules cross at
# `1 / (1 + exp(B))` rather than at 0.5. With `iris` the difference moves 2% of
# rows, all of them near the boundary.
prob_class_rule <- function(x) {
  default <- list(cut = 0.5, op = ">")

  if (inherits(x$fit, "H2OBinomialModel")) {
    threshold <- x$fit@model$default_threshold

    if (!is.numeric(threshold) || length(threshold) != 1) {
      return(default)
    }

    return(list(cut = threshold, op = ">="))
  }

  if (!inherits(x$fit, "ksvm")) {
    return(default)
  }

  # An `ksvm()` fitted with `prob.model = FALSE` carries an empty list here, in
  # which case there is no calibration to undo and 0.5 is the right cut.
  prob_model <- x$fit@prob.model

  if (length(prob_model) < 1 || !is.numeric(prob_model[[1]]$B)) {
    return(default)
  }

  list(cut = 1 / (1 + exp(prob_model[[1]]$B)), op = ">")
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

  deparse_exact(res)
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
