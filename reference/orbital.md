# Turn tidymodels objects into orbital objects

Fitted workflows, parsnip objects, and recipes objects can be turned
into an orbital object that contain all the information needed to
perform predictions.

## Usage

``` r
orbital(x, ..., prefix = ".pred", type = NULL, separate_trees = FALSE)
```

## Arguments

- x:

  A fitted workflow, parsnip, or recipes object.

- ...:

  Not currently used.

- prefix:

  A single string, specifies the prediction naming scheme. If `x`
  produces a prediction, tidymodels standards dictate that the
  predictions will start with `.pred`. This is not a valid name for some
  data bases.

- type:

  A vector of strings, specifies the prediction type. Regression models
  allow for `"numeric"` and classification models allow for `"class"`
  and `"prob"`. Multiple values are allowed to produce hard and soft
  predictions for classification models. Defaults to `NULL` which
  defaults to `"numeric"` for regression models and `"class"` for
  classification models.

- separate_trees:

  A single logical. For tree ensemble models (xgboost, lightgbm,
  catboost, ranger, randomForest), should each tree be output as a
  separate expression? This can improve performance when predicting in
  databases by allowing parallel evaluation of trees. Defaults to
  `FALSE`. See
  [`vignette("separate-trees")`](https://orbital.tidymodels.org/articles/separate-trees.md)
  for details.

## Value

An orbital object.

## Details

An orbital object contains all the information that is needed to perform
predictions. This makes the objects substantially smaller than the
original objects. The main downside with this object is that all the
input checking has been removed, and it is thus up to the user to make
sure the data is correct.

The printing of orbital objects reduce the number of significant digits
for easy viewing, the can be changes by using the `digits` argument of
[`print()`](https://rdrr.io/r/base/print.html) like so
`print(orbital_object, digits = 10)`. The printing likewise truncates
each equation to fit on one line. This can be turned off using the
`truncate` argument like so `print(orbital_object, truncate = FALSE)`.

Full list of supported models and recipes steps can be found here:
[`vignette("supported-models")`](https://orbital.tidymodels.org/articles/supported-models.md).

These objects will not be useful by themselves. They can be used to
[predict()](https://orbital.tidymodels.org/reference/predict.orbital_class.md)
with, or to generate code using functions such as
[`orbital_sql()`](https://orbital.tidymodels.org/reference/orbital_sql.md)
or
[`orbital_dt()`](https://orbital.tidymodels.org/reference/orbital_dt.md).

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

orbital(wf_fit)
#> 
#> ── orbital Object ─────────────────────────────────────────────────────
#> • cyl = (cyl - 6.1875) / 1.785922
#> • disp = (disp - 230.7219) / 123.9387
#> • hp = (hp - 146.6875) / 68.56287
#> • drat = (drat - 3.596562) / 0.5346787
#> • wt = (wt - 3.21725) / 0.9784574
#> • qsec = (qsec - 17.84875) / 1.786943
#> • vs = (vs - 0.4375) / 0.5040161
#> • am = (am - 0.40625) / 0.4989909
#> • gear = (gear - 3.6875) / 0.7378041
#> • carb = (carb - 2.8125) / 1.6152
#> • .pred = 20.09062 + (cyl * -0.199024) + (disp * 1.652752) + (hp ...
#> ───────────────────────────────────────────────────────────────────────
#> 11 equations in total.

# Also works on parsnip object by itself
fit(lm_spec, mpg ~ disp, data = mtcars) |>
  orbital()
#> 
#> ── orbital Object ─────────────────────────────────────────────────────
#> • .pred = 29.59985 + (disp * -0.04121512)
#> ───────────────────────────────────────────────────────────────────────
#> 1 equations in total.

# And prepped recipes
prep(rec_spec) |>
  orbital()
#> 
#> ── orbital Object ─────────────────────────────────────────────────────
#> • cyl = (cyl - 6.1875) / 1.785922
#> • disp = (disp - 230.7219) / 123.9387
#> • hp = (hp - 146.6875) / 68.56287
#> • drat = (drat - 3.596562) / 0.5346787
#> • wt = (wt - 3.21725) / 0.9784574
#> • qsec = (qsec - 17.84875) / 1.786943
#> • vs = (vs - 0.4375) / 0.5040161
#> • am = (am - 0.40625) / 0.4989909
#> • gear = (gear - 3.6875) / 0.7378041
#> • carb = (carb - 2.8125) / 1.6152
#> ───────────────────────────────────────────────────────────────────────
#> 10 equations in total.
```
