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
      * cyl = (cyl - 6.1875) / 1.78592164694654 ...
      * disp = (disp - 230.721875) / 123.938693831382 ...
      * hp = (hp - 146.6875) / 68.5628684893206 ...
      * drat = (drat - 3.5965625) / 0.534678736070971 ...
      * wt = (wt - 3.21725) / 0.978457442989697 ...
      * qsec = (qsec - 17.84875) / 1.78694323609684 ...
      * vs = (vs - 0.4375) / 0.504016128774185 ...
      * am = (am - 0.40625) / 0.498990917235846 ...
      * gear = (gear - 3.6875) / 0.737804065256947 ...
      * carb = (carb - 2.8125) / 1.61519997763185 ...
      * .pred = 20.090625 + (cyl * -0.199023961804222) + (disp * 1.652752216787 ...
      --------------------------------------------------------------------------------
      11 equations in total.

