# dt works

    Code
      orbital_dt(obj)
    Output
      copy(`_DT1`)[, `:=`(c("cyl", "disp", "hp", "drat", "wt", "qsec", 
          "vs", "am", "gear", "carb", ".pred"), {
          cyl <- (cyl - 6.1875)/1.785922
          disp <- (disp - 230.7219)/123.9387
          hp <- (hp - 146.6875)/68.56287
          drat <- (drat - 3.596562)/0.5346787
          wt <- (wt - 3.21725)/0.9784574
          qsec <- (qsec - 17.84875)/1.786943
          vs <- (vs - 0.4375)/0.5040161
          am <- (am - 0.40625)/0.4989909
          gear <- (gear - 3.6875)/0.7378041
          carb <- (carb - 2.8125)/1.6152
          .pred <- 20.09062 + (cyl * -0.199024) + (disp * 
              1.652752) + (hp * -1.472876) + (drat * 
              0.4208515) + (wt * -3.635267) + (qsec * 
              1.467153) + (vs * 0.1601576) + (am * 
              1.25757) + (gear * 0.4835664) + (carb * 
              -0.322102)
          .(cyl, disp, hp, drat, wt, qsec, vs, am, gear, carb, .pred)
      })]

# dt works for lda multiclass

    Code
      orbital_dt(obj)
    Output
      copy(`_DT`)[, `:=`(c("setosa", "versicolor", "virginica", ".pred_setosa", ".pred_versicolor", ".pred_virginica", ".pred_class"), { setosa <- 1/(1 + exp(-2.021974 + (Sepal.Length * -1.531199) + (Sepal.Width * -4.376043) + (Petal.Length * 4.695665) + (Petal.Width * 3.062585) - (-15.47784 + (Sepal.Length * 6.314758) + (Sepal.Width * 12.13932) + (Petal.Length * -16.94642) + (Petal.Width * -20.77005))) + exp(-33.53769 + (Sepal.Length * -4.783559) + (Sepal.Width * -7.763274) + (Petal.Length * 12.25076) + (Petal.Width * 17.70747) - (-15.47784 + (Sepal.Length * 6.314758) + (Sepal.Width * 12.13932) + (Petal.Length * -16.94642) + (Petal.Width * -20.77005)))) versicolor <- 1/(exp(-15.47784 + (Sepal.Length * 6.314758) + (Sepal.Width * 12.13932) + (Petal.Length * -16.94642) + (Petal.Width * -20.77005) - (-2.021974 + (Sepal.Length * -1.531199) + (Sepal.Width * -4.376043) + (Petal.Length * 4.695665) + (Petal.Width * 3.062585))) + 1 + exp(-33.53769 + (Sepal.Length * -4.783559) + (Sepal.Width * -7.763274) + (Petal.Length * 12.25076) + (Petal.Width * 17.70747) - (-2.021974 + (Sepal.Length * -1.531199) + (Sepal.Width * -4.376043) + (Petal.Length * 4.695665) + (Petal.Width * 3.062585)))) virginica <- 1/(exp(-15.47784 + (Sepal.Length * 6.314758) + (Sepal.Width * 12.13932) + (Petal.Length * -16.94642) + (Petal.Width * -20.77005) - (-33.53769 + (Sepal.Length * -4.783559) + (Sepal.Width * -7.763274) + (Petal.Length * 12.25076) + (Petal.Width * 17.70747))) + exp(-2.021974 + (Sepal.Length * -1.531199) + (Sepal.Width * -4.376043) + (Petal.Length * 4.695665) + (Petal.Width * 3.062585) - (-33.53769 + (Sepal.Length * -4.783559) + (Sepal.Width * -7.763274) + (Petal.Length * 12.25076) + (Petal.Width * 17.70747))) + 1) .pred_setosa <- setosa .pred_versicolor <- versicolor .pred_virginica <- virginica .pred_class <- fcase(setosa >= versicolor & setosa >= virginica, "setosa", versicolor >= setosa & versicolor >= virginica, "versicolor", rep(TRUE, .N), "virginica") .(setosa, versicolor, virginica, .pred_setosa, .pred_versicolor, .pred_virginica, .pred_class) })]

# dt works for a binary decision value

    Code
      orbital_dt(obj)
    Output
      copy(`_DT`)[, `:=`(.pred_class = fcase(1.70829 + (Sepal.Length * 0.8510269) + (Sepal.Width * 0.986845) + (Petal.Length * -1.380919) + (Petal.Width * -1.865502) > 0, "versicolor", rep(TRUE, .N), "virginica"))]

# dt works for a binary probability cut away from 0.5

    Code
      orbital_dt(obj)
    Output
      copy(`_DT`)[, `:=`(c(".pred_class", ".pred_versicolor", ".pred_virginica"), { .pred_class <- fcase(1/(1 + exp(-(-14.71509 + (Sepal.Length * -1.074479) + (Sepal.Width * -2.9855) + (Petal.Length * 3.688835) + (Petal.Width * 7.278738)))) > 0.4330417, "virginica", rep(TRUE, .N), "versicolor") .pred_versicolor <- 1 - (1/(1 + exp(-(-14.71509 + (Sepal.Length * -1.074479) + (Sepal.Width * -2.9855) + (Petal.Length * 3.688835) + (Petal.Width * 7.278738))))) .pred_virginica <- 1 - .pred_versicolor .(.pred_class, .pred_versicolor, .pred_virginica) })]

