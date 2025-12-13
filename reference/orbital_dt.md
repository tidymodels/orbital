# Convert to data.table code

Returns [data.table](https://rdatatable.gitlab.io/data.table/) code that
is equivilant to prediction code.

## Usage

``` r
orbital_dt(x)
```

## Arguments

- x:

  An [orbital](https://orbital.tidymodels.org/reference/orbital.md)
  object.

  This function requires [dtplyr](https://dtplyr.tidyverse.org/) to be
  installed to run. The resulting code will likely need to be adopted to
  your use-case. Most likely by removing the initial `copy(data-name)`
  at the start.

## Value

data.table code.

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

orbital_dt(orbital_obj)
#> copy(`_DT1`)[, `:=`(c("cyl", "disp", "hp", "drat", "wt", "qsec", 
#>     "vs", "am", "gear", "carb", ".pred"), {
#>     cyl <- (cyl - 6.1875)/1.78592164694654
#>     disp <- (disp - 230.721875)/123.938693831382
#>     hp <- (hp - 146.6875)/68.5628684893206
#>     drat <- (drat - 3.5965625)/0.534678736070971
#>     wt <- (wt - 3.21725)/0.978457442989697
#>     qsec <- (qsec - 17.84875)/1.78694323609684
#>     vs <- (vs - 0.4375)/0.504016128774185
#>     am <- (am - 0.40625)/0.498990917235846
#>     gear <- (gear - 3.6875)/0.737804065256947
#>     carb <- (carb - 2.8125)/1.61519997763185
#>     .pred <- 20.090625 + (cyl * -0.199023961804221) + (disp * 
#>         1.65275221678761) + (hp * -1.47287569912409) + (drat * 
#>         0.420851499782799) + (wt * -3.63526678164088) + (qsec * 
#>         1.46715321419096) + (vs * 0.160157583474124) + (am * 
#>         1.25757032609057) + (gear * 0.483566388425266) + (carb * 
#>         -0.322101975983201)
#>     .(cyl, disp, hp, drat, wt, qsec, vs, am, gear, carb, .pred)
#> })]
```
