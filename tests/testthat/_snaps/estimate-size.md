# estimate_orbital_size errors for unsupported types

    Code
      estimate_orbital_size(Sys.time())
    Condition
      Error in `estimate_orbital_size()`:
      ! `estimate_orbital_size()` is not implemented for a <POSIXct> object.

# estimate_orbital_size errors for glmnet with multiple lambdas

    Code
      estimate_orbital_size(model)
    Condition
      Error in `estimate_orbital_size()`:
      ! glmnet model has multiple penalty values.
      i Specify a single `penalty` value.

