# adjust_equivocal_zone errors if types aren't set

    Code
      orbital(wf_fit)
    Condition
      Error in `orbital()`:
      x `type` must contain "prob" and "class" to work with `adjust_equivocal_zone()`.

---

    Code
      orbital(wf_fit, type = "prob")
    Condition
      Error in `orbital()`:
      x `type` must contain "prob" and "class" to work with `adjust_equivocal_zone()`.

---

    Code
      orbital(wf_fit, type = "class")
    Condition
      Error in `orbital()`:
      x `type` must contain "prob" and "class" to work with `adjust_equivocal_zone()`.

