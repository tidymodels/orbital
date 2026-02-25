# Turn orbital object into a R function

Returns a R file that contains a function that output predictions when
applied to data frames.

## Usage

``` r
orbital_r_fun(x, name = "orbital_predict", file)
```

## Arguments

- x:

  An [orbital](https://orbital.tidymodels.org/dev/reference/orbital.md)
  object.

- name:

  Name of created function. Defaults to \`"orbital_predict"“.

- file:

  A file name.

## Value

Nothing.

## Details

The generated function is only expected to work on data frame objects.
The generated function doesn't require the orbital package to be loaded.
Depending on what models and steps are used, other packages such as
dplyr will need to be loaded as well.

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

file_name <- tempfile()

orbital_r_fun(orbital_obj, file = file_name)

readLines(file_name)
#>  [1] "orbital_predict <- function(x) {"                                                                                                                                                                                                                                                                            
#>  [2] "with(x, {"                                                                                                                                                                                                                                                                                                   
#>  [3] "   cyl = (cyl - 6.1875) / 1.78592164694654"                                                                                                                                                                                                                                                                  
#>  [4] "   disp = (disp - 230.721875) / 123.938693831382"                                                                                                                                                                                                                                                            
#>  [5] "   hp = (hp - 146.6875) / 68.5628684893206"                                                                                                                                                                                                                                                                  
#>  [6] "   drat = (drat - 3.5965625) / 0.534678736070971"                                                                                                                                                                                                                                                            
#>  [7] "   wt = (wt - 3.21725) / 0.978457442989697"                                                                                                                                                                                                                                                                  
#>  [8] "   qsec = (qsec - 17.84875) / 1.78694323609684"                                                                                                                                                                                                                                                              
#>  [9] "   vs = (vs - 0.4375) / 0.504016128774185"                                                                                                                                                                                                                                                                   
#> [10] "   am = (am - 0.40625) / 0.498990917235846"                                                                                                                                                                                                                                                                  
#> [11] "   gear = (gear - 3.6875) / 0.737804065256947"                                                                                                                                                                                                                                                               
#> [12] "   carb = (carb - 2.8125) / 1.61519997763185"                                                                                                                                                                                                                                                                
#> [13] "   .pred = 20.090625 + (cyl * -0.199023961804221) + (disp * 1.65275221678761) + (hp * -1.47287569912409) + (drat * 0.420851499782799) + (wt * -3.63526678164088) + (qsec * 1.46715321419096) + (vs * 0.160157583474124) + (am * 1.25757032609057) + (gear * 0.483566388425266) + (carb * -0.322101975983201)"
#> [14] "  .pred"                                                                                                                                                                                                                                                                                                     
#> [15] "  })"                                                                                                                                                                                                                                                                                                        
#> [16] "}"                                                                                                                                                                                                                                                                                                           
```
