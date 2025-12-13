# Save orbital object as json file

Saving an orbital object to disk in a human and machine readable way.

## Usage

``` r
orbital_json_write(x, path)
```

## Arguments

- x:

  An [orbital](https://orbital.tidymodels.org/reference/orbital.md)
  object.

- path:

  file on disk.

## Value

Nothing.

## Details

The structure of the resulting JSON file allows for easy reading, both
by orbital itself with
[`orbital_json_read()`](https://orbital.tidymodels.org/reference/orbital_json_read.md),
but potentially by other packages and langauges. The file is versioned
by the `version` field to allow for changes why being backwards
combatible with older file versions.

## See also

[`orbital_json_read()`](https://orbital.tidymodels.org/reference/orbital_json_read.md)

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

tmp_file <- tempfile()

orbital_json_write(orbital_obj, tmp_file)

readLines(tmp_file)
#>  [1] "{"                                                                                                                                                                                                                                                                                                                   
#>  [2] "  \"actions\": {"                                                                                                                                                                                                                                                                                                    
#>  [3] "    \"cyl\": \"(cyl - 6.1875) / 1.78592164694654\","                                                                                                                                                                                                                                                                 
#>  [4] "    \"disp\": \"(disp - 230.721875) / 123.938693831382\","                                                                                                                                                                                                                                                           
#>  [5] "    \"hp\": \"(hp - 146.6875) / 68.5628684893206\","                                                                                                                                                                                                                                                                 
#>  [6] "    \"drat\": \"(drat - 3.5965625) / 0.534678736070971\","                                                                                                                                                                                                                                                           
#>  [7] "    \"wt\": \"(wt - 3.21725) / 0.978457442989697\","                                                                                                                                                                                                                                                                 
#>  [8] "    \"qsec\": \"(qsec - 17.84875) / 1.78694323609684\","                                                                                                                                                                                                                                                             
#>  [9] "    \"vs\": \"(vs - 0.4375) / 0.504016128774185\","                                                                                                                                                                                                                                                                  
#> [10] "    \"am\": \"(am - 0.40625) / 0.498990917235846\","                                                                                                                                                                                                                                                                 
#> [11] "    \"gear\": \"(gear - 3.6875) / 0.737804065256947\","                                                                                                                                                                                                                                                              
#> [12] "    \"carb\": \"(carb - 2.8125) / 1.61519997763185\","                                                                                                                                                                                                                                                               
#> [13] "    \".pred\": \"20.090625 + (cyl * -0.199023961804221) + (disp * 1.65275221678761) + (hp * -1.47287569912409) + (drat * 0.420851499782799) + (wt * -3.63526678164088) + (qsec * 1.46715321419096) + (vs * 0.160157583474124) + (am * 1.25757032609057) + (gear * 0.483566388425266) + (carb * -0.322101975983201)\""
#> [14] "  },"                                                                                                                                                                                                                                                                                                                
#> [15] "  \"pred_names\": \".pred\","                                                                                                                                                                                                                                                                                        
#> [16] "  \"version\": 2"                                                                                                                                                                                                                                                                                                    
#> [17] "}"                                                                                                                                                                                                                                                                                                                   
```
