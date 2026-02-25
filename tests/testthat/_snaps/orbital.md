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
      * cyl = (cyl - 6.1875) / 1.7859
      * disp = (disp - 230.7219) / 123.9387
      * hp = (hp - 146.6875) / 68.5628
      * drat = (drat - 3.5965) / 0.5346
      * wt = (wt - 3.2172) / 0.9784
      * qsec = (qsec - 17.8487) / 1.7869
      * vs = (vs - 0.4375) / 0.5040
      * am = (am - 0.4062) / 0.4989
      * gear = (gear - 3.6875) / 0.7378
      * carb = (carb - 2.8125) / 1.6152
      * .pred = 20.0906 + (cyl * -0.1990) + (disp * 1.6527) + (hp * -1.472 ...
      --------------------------------------------------------------------------------
      11 equations in total.

---

    Code
      print(orbital(wf_fit), digits = 2)
    Message
      
      -- orbital Object --------------------------------------------------------------
      * cyl = (cyl - 6.2) / 1.8
      * disp = (disp - 230) / 120
      * hp = (hp - 150) / 69
      * drat = (drat - 3.6) / 0.53
      * wt = (wt - 3.2) / 0.98
      * qsec = (qsec - 18) / 1.8
      * vs = (vs - 0.44) / 0.5
      * am = (am - 0.41) / 0.5
      * gear = (gear - 3.7) / 0.74
      * carb = (carb - 2.8) / 1.6
      * .pred = 20 + (cyl * -0.2) + (disp * 1.7) + (hp * -1.5) + (drat * 0.42) ...
      --------------------------------------------------------------------------------
      11 equations in total.

---

    Code
      print(orbital(wf_fit), truncate = FALSE)
    Message
      
      -- orbital Object --------------------------------------------------------------
      * cyl = (cyl - 6.1875) / 1.7859
      * disp = (disp - 230.7219) / 123.9387
      * hp = (hp - 146.6875) / 68.5628
      * drat = (drat - 3.5965) / 0.5346
      * wt = (wt - 3.2172) / 0.9784
      * qsec = (qsec - 17.8487) / 1.7869
      * vs = (vs - 0.4375) / 0.5040
      * am = (am - 0.4062) / 0.4989
      * gear = (gear - 3.6875) / 0.7378
      * carb = (carb - 2.8125) / 1.6152
      * .pred = 20.0906 + (cyl * -0.1990) + (disp * 1.6527) + (hp * -1.4728) +
      (drat * 0.4208) + (wt * -3.6352) + (qsec * 1.4671) + (vs * 0.1601) +
      (am * 1.2575) + (gear * 0.4835) + (carb * -0.3221)
      --------------------------------------------------------------------------------
      11 equations in total.

