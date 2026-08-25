# a decision value routes to a cut at zero, and refuses prob

    Code
      orbital(fit, type = "prob")
    Condition
      Error in `orbital()`:
      ! "prob" predictions are not available for this model.
      i It produces an uncalibrated decision value rather than a probability.
      i Use `type = "class"` instead.

# a class-only model routes its label through, and refuses prob

    Code
      orbital(fit, type = "prob")
    Condition
      Error in `orbital()`:
      ! "prob" predictions are not available for this model.
      i It predicts a class directly, with no probability behind it.
      i Use `type = "class"` instead.

# a model tidypredict cannot describe is refused

    Code
      route_fallback(rlang::expr(1 + 1), fit, "classification", "class")
    Condition
      Error:
      ! Classification output for a model of class <made_up> is not yet supported.
      i The model itself is supported for "regression" mode.

# a level-count mismatch is refused

    Code
      order_prob_eqs(c(a = "1", b = "2"), fit, fit$lvl, rlang::current_env())
    Condition
      Error:
      ! Model returned 2 expressions for 3 outcome levels.

