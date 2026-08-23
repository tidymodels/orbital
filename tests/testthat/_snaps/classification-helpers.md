# binary_from_decision refuses to invent a probability

    Code
      orbital:::binary_from_decision("d", c("class", "prob"), c("no", "yes"))
    Condition
      Error:
      ! "prob" predictions are not available for this model.
      i It produces an uncalibrated decision value rather than a probability.
      i Use `type = "class"` instead.

