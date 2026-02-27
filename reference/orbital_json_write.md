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
#>  [3] "    \"cyl\": \"(cyl - 6.1875) / 1.7859216469465444\","                                                                                                                                                                                                                                                                                           
#>  [4] "    \"disp\": \"(disp - 230.72187500000001) / 123.93869383138194\","                                                                                                                                                                                                                                                                             
#>  [5] "    \"hp\": \"(hp - 146.6875) / 68.562868489320593\","                                                                                                                                                                                                                                                                                           
#>  [6] "    \"drat\": \"(drat - 3.5965625000000001) / 0.53467873607097149\","                                                                                                                                                                                                                                                                            
#>  [7] "    \"wt\": \"(wt - 3.2172499999999999) / 0.97845744298969672\","                                                                                                                                                                                                                                                                                
#>  [8] "    \"qsec\": \"(qsec - 17.848749999999999) / 1.7869432360968429\","                                                                                                                                                                                                                                                                             
#>  [9] "    \"vs\": \"(vs - 0.4375) / 0.50401612877418533\","                                                                                                                                                                                                                                                                                            
#> [10] "    \"am\": \"(am - 0.40625) / 0.49899091723584604\","                                                                                                                                                                                                                                                                                           
#> [11] "    \"gear\": \"(gear - 3.6875) / 0.73780406525694708\","                                                                                                                                                                                                                                                                                        
#> [12] "    \"carb\": \"(carb - 2.8125) / 1.6151999776318522\","                                                                                                                                                                                                                                                                                         
#> [13] "    \".pred\": \"20.090624999999996 + (cyl * -0.1990239618042213) + (disp * 1.6527522167876059) + (hp * -1.4728756991240948) + (drat * 0.42085149978279884) + (wt * -3.6352667816408784) + (qsec * 1.4671532141909569) + (vs * 0.16015758347412398) + (am * 1.2575703260905717) + (gear * 0.48356638842526595) + (carb * -0.32210197598320101)\""
#> [14] "  },"                                                                                                                                                                                                                                                                                                                                            
#> [15] "  \"pred_names\": \".pred\","                                                                                                                                                                                                                                                                                                                    
#> [16] "  \"version\": 2"                                                                                                                                                                                                                                                                                                                                
#> [17] "}"                                                                                                                                                                                                                                                                                                                                               
```
