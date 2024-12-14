# normal usage works works

    Code
      orbital(wf_fit)
    Condition
      Error in `orbital()`:
      ! A model of class <train.kknn> is not supported.

# errors on invalid modes

    Code
      orbital(lm_fit)
    Condition
      Error in `orbital()`:
      ! Only models with modes "regression" and "classification" are supported.  Not "invalid mode".

