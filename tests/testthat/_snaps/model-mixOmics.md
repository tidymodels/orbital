# pls() refuses type = class

    Code
      orbital(fit, type = "class")
    Condition
      Error in `orbital()`:
      ! "class" predictions are not available for this model.
      i It assigns a class by distance to the class centroid, which the per-level values do not determine.
      i Use `type = "prob"` instead.

