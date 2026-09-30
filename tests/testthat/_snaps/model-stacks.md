# orbital() errors early on invalid `type` for a model_stack

    Code
      orbital(st, type = "bogus")
    Condition
      Error in `orbital()`:
      ! `type` must be one of "numeric", "class", or "prob", not "bogus".

# orbital() errors on a stack that hasn't been fit_members()

    Code
      orbital(st)
    Condition
      Error in `orbital()`:
      ! `x` must be a fully fitted <model_stack>.
      i Run `stacks::fit_members()` on the blended stack first.

