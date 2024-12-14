# type argument checking works

    Code
      orbital(wf_fit, type = "invalid")
    Condition
      Error in `orbital()`:
      ! `type` must be one of "numeric", "class", or "prob", not "invalid".

---

    Code
      orbital(wf_fit, type = "class")
    Condition
      Error in `orbital()`:
      ! `type` can only be "numeric" for model with mode "regression", not "class".

---

    Code
      orbital(wf_fit, type = c("class", "numeric"))
    Condition
      Error in `orbital()`:
      ! `type` can only be "numeric" for model with mode "regression", not "class" and "numeric".

---

    Code
      orbital(wf_fit, type = "invalid")
    Condition
      Error in `orbital()`:
      ! `type` must be one of "numeric", "class", or "prob", not "invalid".

---

    Code
      orbital(wf_fit, type = "numeric")
    Condition
      Error in `orbital()`:
      ! `type` can only be "class" or "prob" for model with mode "classification", not "numeric".

---

    Code
      orbital(wf_fit, type = c("class", "numeric"))
    Condition
      Error in `orbital()`:
      ! `type` can only be "class" or "prob" for model with mode "classification", not "class" and "numeric".

