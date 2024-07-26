# dt works

    Code
      orbital_dt(obj)
    Output
      copy(`_DT2`)[, `:=`(c("cyl", "disp", "hp", "drat", "wt", "qsec", 
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

