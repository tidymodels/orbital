# orbital() errors for invalid type argument

    Code
      orbital(fit, type = "invalid")
    Condition
      Error in `orbital()`:
      ! `type` must be one of "numeric", "class", or "prob", not "invalid".

# orbital() errors when using classification type for regression model

    Code
      orbital(fit, type = "class")
    Condition
      Error in `orbital()`:
      ! `type` can only be "numeric" for model with mode "regression", not "class".

# orbital() errors when using regression type for classification model

    Code
      orbital(fit, type = "numeric")
    Condition
      Error in `orbital()`:
      ! `type` can only be "class" or "prob" for model with mode "classification", not "numeric".

