# Convert orbital objects to quosures

Use orbital object splicing function to apply orbital prediction in a
quosure aware function such as
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

## Usage

``` r
orbital_inline(x)
```

## Arguments

- x:

  An [orbital](https://orbital.tidymodels.org/reference/orbital.md)
  object.

## Value

a list of
[quosures](https://rlang.r-lib.org/reference/defusing-advanced.html).

## Details

This function is mostly going to be used for [Dots
Injection](https://rlang.r-lib.org/reference/topic-inject.html#dots-injection).
This function is used internally in
[predict()](https://orbital.tidymodels.org/reference/predict.orbital_class.md),
but is also exported for user flexibility. Should be used with `!!!` as
seen in the examples.

Note should be taken that using this function modifies existing
variables and creates new variables, unlike
[predict()](https://orbital.tidymodels.org/reference/predict.orbital_class.md)
which only returns predictions.

## Examples

``` r
library(workflows)
library(recipes)
library(parsnip)

rec_spec <- recipe(mpg ~ ., data = mtcars) |>
  step_normalize(all_numeric_predictors())

lm_spec <- linear_reg()

wf_spec <- workflow(rec_spec, lm_spec)

wf_fit <- fit(wf_spec, mtcars)

orbital_obj <- orbital(wf_fit)

orbital_inline(orbital_obj)
#> <list_of<quosure>>
#> 
#> $cyl
#> <quosure>
#> expr: ^(cyl - 6.1875) / 1.78592164694654
#> env:  global
#> 
#> $disp
#> <quosure>
#> expr: ^(disp - 230.721875) / 123.938693831382
#> env:  global
#> 
#> $hp
#> <quosure>
#> expr: ^(hp - 146.6875) / 68.5628684893206
#> env:  global
#> 
#> $drat
#> <quosure>
#> expr: ^(drat - 3.5965625) / 0.534678736070971
#> env:  global
#> 
#> $wt
#> <quosure>
#> expr: ^(wt - 3.21725) / 0.978457442989697
#> env:  global
#> 
#> $qsec
#> <quosure>
#> expr: ^(qsec - 17.84875) / 1.78694323609684
#> env:  global
#> 
#> $vs
#> <quosure>
#> expr: ^(vs - 0.4375) / 0.504016128774185
#> env:  global
#> 
#> $am
#> <quosure>
#> expr: ^(am - 0.40625) / 0.498990917235846
#> env:  global
#> 
#> $gear
#> <quosure>
#> expr: ^(gear - 3.6875) / 0.737804065256947
#> env:  global
#> 
#> $carb
#> <quosure>
#> expr: ^(carb - 2.8125) / 1.61519997763185
#> env:  global
#> 
#> $.pred
#> <quosure>
#> expr: ^20.090625 + (cyl * -0.199023961804221) + (disp *
#>           1.65275221678761) + (hp * -1.47287569912409) + (drat *
#>           0.420851499782799) + (wt * -3.63526678164088) + (qsec *
#>           1.46715321419096) + (vs * 0.160157583474124) + (am *
#>           1.25757032609057) + (gear * 0.483566388425266) + (carb *
#>           -0.322101975983201)
#> env:  global
#> 

library(dplyr)

mtcars |>
  mutate(!!!orbital_inline(orbital_obj))
#>                      mpg        cyl        disp          hp
#> Mazda RX4           21.0 -0.1049878 -0.57061982 -0.53509284
#> Mazda RX4 Wag       21.0 -0.1049878 -0.57061982 -0.53509284
#> Datsun 710          22.8 -1.2248578 -0.99018209 -0.78304046
#> Hornet 4 Drive      21.4 -0.1049878  0.22009369 -0.53509284
#> Hornet Sportabout   18.7  1.0148821  1.04308123  0.41294217
#> Valiant             18.1 -0.1049878 -0.04616698 -0.60801861
#> Duster 360          14.3  1.0148821  1.04308123  1.43390296
#> Merc 240D           24.4 -1.2248578 -0.67793094 -1.23518023
#> Merc 230            22.8 -1.2248578 -0.72553512 -0.75387015
#> Merc 280            19.2 -0.1049878 -0.50929918 -0.34548584
#> Merc 280C           17.8 -0.1049878 -0.50929918 -0.34548584
#> Merc 450SE          16.4  1.0148821  0.36371309  0.48586794
#> Merc 450SL          17.3  1.0148821  0.36371309  0.48586794
#> Merc 450SLC         15.2  1.0148821  0.36371309  0.48586794
#> Cadillac Fleetwood  10.4  1.0148821  1.94675381  0.85049680
#> Lincoln Continental 10.4  1.0148821  1.84993175  0.99634834
#> Chrysler Imperial   14.7  1.0148821  1.68856165  1.21512565
#> Fiat 128            32.4 -1.2248578 -1.22658929 -1.17683962
#> Honda Civic         30.4 -1.2248578 -1.25079481 -1.38103178
#> Toyota Corolla      33.9 -1.2248578 -1.28790993 -1.19142477
#> Toyota Corona       21.5 -1.2248578 -0.89255318 -0.72469984
#> Dodge Challenger    15.5  1.0148821  0.70420401  0.04831332
#> AMC Javelin         15.2  1.0148821  0.59124494  0.04831332
#> Camaro Z28          13.3  1.0148821  0.96239618  1.43390296
#> Pontiac Firebird    19.2  1.0148821  1.36582144  0.41294217
#> Fiat X1-9           27.3 -1.2248578 -1.22416874 -1.17683962
#> Porsche 914-2       26.0 -1.2248578 -0.89093948 -0.81221077
#> Lotus Europa        30.4 -1.2248578 -1.09426581 -0.49133738
#> Ford Pantera L      15.8  1.0148821  0.97046468  1.71102089
#> Ferrari Dino        19.7 -0.1049878 -0.69164740  0.41294217
#> Maserati Bora       15.0  1.0148821  0.56703942  2.74656682
#> Volvo 142E          21.4 -1.2248578 -0.88529152 -0.54967799
#>                            drat           wt        qsec         vs
#> Mazda RX4            0.56751369 -0.610399567 -0.77716515 -0.8680278
#> Mazda RX4 Wag        0.56751369 -0.349785269 -0.46378082 -0.8680278
#> Datsun 710           0.47399959 -0.917004624  0.42600682  1.1160357
#> Hornet 4 Drive      -0.96611753 -0.002299538  0.89048716  1.1160357
#> Hornet Sportabout   -0.83519779  0.227654255 -0.46378082 -0.8680278
#> Valiant             -1.56460776  0.248094592  1.32698675  1.1160357
#> Duster 360          -0.72298087  0.360516446 -1.12412636 -0.8680278
#> Merc 240D            0.17475447 -0.027849959  1.20387148  1.1160357
#> Merc 230             0.60491932 -0.068730634  2.82675459  1.1160357
#> Merc 280             0.60491932  0.227654255  0.25252621  1.1160357
#> Merc 280C            0.60491932  0.227654255  0.58829513  1.1160357
#> Merc 450SE          -0.98482035  0.871524874 -0.25112717 -0.8680278
#> Merc 450SL          -0.98482035  0.524039143 -0.13920420 -0.8680278
#> Merc 450SLC         -0.98482035  0.575139986  0.08464175 -0.8680278
#> Cadillac Fleetwood  -1.24665983  2.077504765  0.07344945 -0.8680278
#> Lincoln Continental -1.11574009  2.255335698 -0.01608893 -0.8680278
#> Chrysler Imperial   -0.68557523  2.174596366 -0.23993487 -0.8680278
#> Fiat 128             0.90416444 -1.039646647  0.90727560  1.1160357
#> Honda Civic          2.49390411 -1.637526508  0.37564148  1.1160357
#> Toyota Corolla       1.16600392 -1.412682800  1.14790999  1.1160357
#> Toyota Corona        0.19345729 -0.768812180  1.20946763  1.1160357
#> Dodge Challenger    -1.56460776  0.309415603 -0.54772305 -0.8680278
#> AMC Javelin         -0.83519779  0.222544170 -0.30708866 -0.8680278
#> Camaro Z28           0.24956575  0.636460997 -1.36476075 -0.8680278
#> Pontiac Firebird    -0.96611753  0.641571082 -0.44699237 -0.8680278
#> Fiat X1-9            0.90416444 -1.310481114  0.58829513  1.1160357
#> Porsche 914-2        1.55876313 -1.100967659 -0.64285758 -0.8680278
#> Lotus Europa         0.32437703 -1.741772228 -0.53093460  1.1160357
#> Ford Pantera L       1.16600392 -0.048290296 -1.87401028 -0.8680278
#> Ferrari Dino         0.04383473 -0.457097039 -1.31439542 -0.8680278
#> Maserati Bora       -0.10578782  0.360516446 -1.81804880 -0.8680278
#> Volvo 142E           0.96027290 -0.446876870  0.42041067  1.1160357
#>                             am       gear       carb    .pred
#> Mazda RX4            1.1899014  0.4235542  0.7352031 22.59951
#> Mazda RX4 Wag        1.1899014  0.4235542  0.7352031 22.11189
#> Datsun 710           1.1899014  0.4235542 -1.1221521 26.25064
#> Hornet 4 Drive      -0.8141431 -0.9318192 -1.1221521 21.23740
#> Hornet Sportabout   -0.8141431 -0.9318192 -0.5030337 17.69343
#> Valiant             -0.8141431 -0.9318192 -1.1221521 20.38304
#> Duster 360          -0.8141431 -0.9318192  0.7352031 14.38626
#> Merc 240D           -0.8141431  0.4235542 -0.5030337 22.49601
#> Merc 230            -0.8141431  0.4235542 -0.5030337 24.41909
#> Merc 280            -0.8141431  0.4235542  0.7352031 18.69903
#> Merc 280C           -0.8141431  0.4235542  0.7352031 19.19165
#> Merc 450SE          -0.8141431 -0.9318192  0.1160847 14.17216
#> Merc 450SL          -0.8141431 -0.9318192  0.1160847 15.59957
#> Merc 450SLC         -0.8141431 -0.9318192  0.1160847 15.74222
#> Cadillac Fleetwood  -0.8141431 -0.9318192  0.7352031 12.03401
#> Lincoln Continental -0.8141431 -0.9318192  0.7352031 10.93644
#> Chrysler Imperial   -0.8141431 -0.9318192  0.7352031 10.49363
#> Fiat 128             1.1899014  0.4235542 -1.1221521 27.77291
#> Honda Civic          1.1899014  0.4235542 -0.5030337 29.89674
#> Toyota Corolla       1.1899014  0.4235542 -1.1221521 29.51237
#> Toyota Corona       -0.8141431 -0.9318192 -1.1221521 23.64310
#> Dodge Challenger    -0.8141431 -0.9318192 -0.5030337 16.94305
#> AMC Javelin         -0.8141431 -0.9318192 -0.5030337 17.73218
#> Camaro Z28          -0.8141431 -0.9318192  0.7352031 13.30602
#> Pontiac Firebird    -0.8141431 -0.9318192 -0.5030337 16.69168
#> Fiat X1-9            1.1899014  0.4235542 -1.1221521 28.29347
#> Porsche 914-2        1.1899014  1.7789276 -0.5030337 26.15295
#> Lotus Europa         1.1899014  1.7789276 -0.5030337 27.63627
#> Ford Pantera L       1.1899014  1.7789276  0.7352031 18.87004
#> Ferrari Dino         1.1899014  1.7789276  1.9734398 19.69383
#> Maserati Bora        1.1899014  1.7789276  3.2116766 13.94112
#> Volvo 142E           1.1899014  0.4235542 -0.5030337 24.36827
```
