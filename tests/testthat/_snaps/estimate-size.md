# estimate_orbital_size errors for unsupported types

    Code
      estimate_orbital_size(Sys.time())
    Condition
      Error in `estimate_orbital_size()`:
      ! `estimate_orbital_size()` is not implemented for a <POSIXct> object.
      i Use `orbital()` to build the expression and measure it, or <https://github.com/tidymodels/orbital/issues> to request an estimate for this model.

# estimate_orbital_size errors for glmnet with multiple lambdas

    Code
      estimate_orbital_size(model)
    Condition
      Error in `estimate_orbital_size()`:
      ! glmnet model has multiple penalty values.
      i Specify a single `penalty` value.

# estimate_orbital_size refuses a workflow whose model has no estimate

    Code
      estimate_orbital_size(wf)
    Condition
      Error in `estimate_orbital_size()`:
      ! `estimate_orbital_size()` is not implemented for a <nnet.formula> object.
      i Use `orbital()` to build the expression and measure it, or <https://github.com/tidymodels/orbital/issues> to request an estimate for this model.

# estimate_orbital_size refuses a model it has no estimate for

    Code
      estimate_orbital_size(fit$fit)
    Condition
      Error in `estimate_orbital_size()`:
      ! `estimate_orbital_size()` is not implemented for a <nnet.formula> object.
      i Use `orbital()` to build the expression and measure it, or <https://github.com/tidymodels/orbital/issues> to request an estimate for this model.

