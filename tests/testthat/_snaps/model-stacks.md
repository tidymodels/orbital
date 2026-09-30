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

# orbital() errors when `type` doesn't match a model_stack's mode

    Code
      orbital(st, type = "prob")
    Condition
      Error in `orbital()`:
      ! `type` can only be "numeric" for model with mode "regression", not "prob".

# orbital() wraps a member build failure with the member's name

    Code
      orbital(st)
    Condition
      Error in `orbital()`:
      ! Failed to build equations for stack member "knn_res".
      Caused by error in `orbital()`:
      ! A model of class <train.kknn> is not supported.

# orbital() errors when stack members produce colliding equation names

    Code
      orbital(st)
    Condition
      Error in `orbital()`:
      ! Stack members produced colliding equation names: "dup".

# check_fitted_stack requires member_fits

    Code
      orbital:::check_fitted_stack(list(member_fits = NULL, coefs = NULL))
    Condition
      Error:
      ! `x` must be a fully fitted <model_stack>.
      i Run `stacks::fit_members()` on the blended stack first.

---

    Code
      orbital:::check_fitted_stack(list(member_fits = list(), coefs = NULL))
    Condition
      Error:
      ! `x` must be a fully fitted <model_stack>.
      i Run `stacks::fit_members()` on the blended stack first.

# check_fitted_stack requires coefs to be a fitted model_fit

    Code
      orbital:::check_fitted_stack(list(member_fits = list(a = 1), coefs = list()))
    Condition
      Error:
      ! `x` must be a fully fitted <model_stack>.
      i Run `stacks::fit_members()` on the blended stack first.

