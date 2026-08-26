# bart(dbarts) errors for classification

    Code
      orbital(fit, type = "class")
    Condition
      Error in `check_bart_supported()`:
      ! Classification `dbarts::bart()` models are not supported.
      i Only regression models can be converted to tidy formulas.
      i Classification uses the probit link, which cannot be translated to SQL.

