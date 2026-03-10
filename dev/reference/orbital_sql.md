# Convert to SQL code

Returns SQL code that is equivilant to prediction code.

## Usage

``` r
orbital_sql(x, con)
```

## Arguments

- x:

  An [orbital](https://orbital.tidymodels.org/dev/reference/orbital.md)
  object.

- con:

  A connection object.

## Value

SQL code.

## Details

This function requires a database connection object, as the resulting
code SQL code can differ depending on the type of database.

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

library(dbplyr)
#> 
#> Attaching package: ‘dbplyr’
#> The following objects are masked from ‘package:dplyr’:
#> 
#>     ident, sql
con <- simulate_dbi()

orbital_sql(orbital_obj, con)
#> <SQL> (`cyl` - 6.1875) / 1.78592164694654 AS cyl
#> <SQL> (`disp` - 230.721875) / 123.938693831382 AS disp
#> <SQL> (`hp` - 146.6875) / 68.5628684893206 AS hp
#> <SQL> (`drat` - 3.5965625) / 0.534678736070971 AS drat
#> <SQL> (`wt` - 3.21725) / 0.978457442989697 AS wt
#> <SQL> (`qsec` - 17.84875) / 1.78694323609684 AS qsec
#> <SQL> (`vs` - 0.4375) / 0.504016128774185 AS vs
#> <SQL> (`am` - 0.40625) / 0.498990917235846 AS am
#> <SQL> (`gear` - 3.6875) / 0.737804065256947 AS gear
#> <SQL> (`carb` - 2.8125) / 1.61519997763185 AS carb
#> <SQL> (((((((((20.090625 + (`cyl` * -0.199023961804226)) + (`disp` * 1.65275221678761)) + (`hp` * -1.47287569912409)) + (`drat` * 0.420851499782798)) + (`wt` * -3.63526678164088)) + (`qsec` * 1.46715321419096)) + (`vs` * 0.160157583474125)) + (`am` * 1.25757032609057)) + (`gear` * 0.483566388425265)) + (`carb` * -0.322101975983201) AS .pred
```
