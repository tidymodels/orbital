# normal usage works works

    Code
      orbital(wf_fit)
    Condition
      Error in `orbital()`:
      ! A model of class <train.kknn> is not supported.

# bare model fits are refused

    Code
      orbital(rpart::rpart(mpg ~ ., mtcars))
    Condition
      Error in `orbital()`:
      ! `x` must be a workflow, parsnip, or recipe object, not a bare <rpart> fit.
      i Fit the model with `parsnip::fit()` first.

---

    Code
      orbital(partykit::ctree(mpg ~ ., mtcars))
    Condition
      Error in `orbital()`:
      ! `x` must be a workflow, parsnip, or recipe object, not a bare <constparty> fit.
      i Fit the model with `parsnip::fit()` first.

# bare fits that already errored now say why

    Code
      orbital(randomForest::randomForest(mpg ~ ., mtcars))
    Condition
      Error in `orbital()`:
      ! `x` must be a workflow, parsnip, or recipe object, not a bare <randomForest.formula> fit.
      i Fit the model with `parsnip::fit()` first.

# errors from native methods are not swallowed by the fallback

    Code
      orbital(fit)
    Condition
      Error:
      ! Bug inside a native method.

# errors on invalid modes

    Code
      orbital(lm_fit)
    Condition
      Error in `orbital()`:
      ! Only models with modes "regression" and "classification" are supported.  Not "invalid mode".

# type argument checking works

    Code
      orbital(lm_fit, type = "invalid")
    Condition
      Error in `orbital()`:
      ! `type` must be one of "numeric", "class", or "prob", not "invalid".

---

    Code
      orbital(lm_fit, type = "class")
    Condition
      Error in `orbital()`:
      ! `type` can only be "numeric" for model with mode "regression", not "class".

---

    Code
      orbital(lm_fit, type = c("class", "numeric"))
    Condition
      Error in `orbital()`:
      ! `type` can only be "numeric" for model with mode "regression", not "class" and "numeric".

---

    Code
      orbital(lm_fit, type = "invalid")
    Condition
      Error in `orbital()`:
      ! `type` must be one of "numeric", "class", or "prob", not "invalid".

---

    Code
      orbital(lm_fit, type = "numeric")
    Condition
      Error in `orbital()`:
      ! `type` can only be "class" or "prob" for model with mode "classification", not "numeric".

---

    Code
      orbital(lm_fit, type = c("class", "numeric"))
    Condition
      Error in `orbital()`:
      ! `type` can only be "class" or "prob" for model with mode "classification", not "class" and "numeric".

