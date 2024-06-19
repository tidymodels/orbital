# orbital errors on non-trained workflow

    Code
      orbital(wf_spec)
    Condition
      Error in `orbital()`:
      ! `x` must be a fully trained <workflow>.

# orbital errors untrained recipe

    Code
      orbital(rec_spec)
    Condition
      Error in `orbital()`:
      ! recipe must be fully trained.

# orbital errors on non-trained parsnip

    Code
      orbital(lm_spec)
    Condition
      Error in `orbital()`:
      ! `x` must be fitted model.

# orbital errors nicely on post-processing

    Code
      orbital(wf_fit)
    Condition
      Error in `orbital()`:
      ! post-processing is not yet supported in orbital.

# orbital errors on wrong input

    Code
      orbital(lm(mpg ~ ., data = mtcars))
    Condition
      Error in `orbital()`:
      ! Is not implemented for a <lm> object.

# orbital printing works

    Code
      orbital(wf_fit)
    Message
      
      -- orbital Object --------------------------------------------------------------
      * cyl = (cyl - 6.1875) / 1.785922 ...
      * disp = (disp - 230.7219) / 123.9387 ...
      * hp = (hp - 146.6875) / 68.56287 ...
      * drat = (drat - 3.596562) / 0.5346787 ...
      * wt = (wt - 3.21725) / 0.9784574 ...
      * qsec = (qsec - 17.84875) / 1.786943 ...
      * vs = (vs - 0.4375) / 0.5040161 ...
      * am = (am - 0.40625) / 0.4989909 ...
      * gear = (gear - 3.6875) / 0.7378041 ...
      * carb = (carb - 2.8125) / 1.6152 ...
      * .pred = 20.09062 + (cyl * -0.199024) + (disp * 1.652752 ...
      --------------------------------------------------------------------------------
      11 equations in total.

