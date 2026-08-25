# normal usage works works

    Code
      orbital(wf_fit)
    Condition
      Error in `orbital()`:
      ! A model of class <train.kknn> is not supported.

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

