# Prediction using orbital objects

Running prediction on data frame of remote database table, without
needing to load original packages used to fit model.

## Usage

``` r
# S3 method for class 'orbital_class'
predict(object, new_data, ...)
```

## Arguments

- object:

  An [orbital](https://orbital.tidymodels.org/reference/orbital.md)
  object.

- new_data:

  A data frame or remote database table.

- ...:

  Not currently used.

## Value

A modified data frame or remote database table.

## Details

Using this function should give identical results to running
[`predict()`](https://rdrr.io/r/stats/predict.html) or
[`bake()`](https://recipes.tidymodels.org/reference/bake.html) on the
orginal object.

The prediction done will only return prediction colunms, a opposed to
returning all modified functions as done with
[`orbital_inline()`](https://orbital.tidymodels.org/reference/orbital_inline.md).

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

predict(orbital_obj, mtcars)
#>                        .pred
#> Mazda RX4           22.59951
#> Mazda RX4 Wag       22.11189
#> Datsun 710          26.25064
#> Hornet 4 Drive      21.23740
#> Hornet Sportabout   17.69343
#> Valiant             20.38304
#> Duster 360          14.38626
#> Merc 240D           22.49601
#> Merc 230            24.41909
#> Merc 280            18.69903
#> Merc 280C           19.19165
#> Merc 450SE          14.17216
#> Merc 450SL          15.59957
#> Merc 450SLC         15.74222
#> Cadillac Fleetwood  12.03401
#> Lincoln Continental 10.93644
#> Chrysler Imperial   10.49363
#> Fiat 128            27.77291
#> Honda Civic         29.89674
#> Toyota Corolla      29.51237
#> Toyota Corona       23.64310
#> Dodge Challenger    16.94305
#> AMC Javelin         17.73218
#> Camaro Z28          13.30602
#> Pontiac Firebird    16.69168
#> Fiat X1-9           28.29347
#> Porsche 914-2       26.15295
#> Lotus Europa        27.63627
#> Ford Pantera L      18.87004
#> Ferrari Dino        19.69383
#> Maserati Bora       13.94112
#> Volvo 142E          24.36827
```
