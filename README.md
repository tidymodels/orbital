
<!-- README.md is generated from README.Rmd. Please edit that file -->

# orbital

<!-- badges: start -->
<!-- badges: end -->

The goal of orbital is to enable running predictions of tidymodels
[workflows](https://workflows.tidymodels.org/) inside databases.

## Installation

To install it, use:

``` r
install.packages("orbital")
```

You can install the development version of orbital from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("tidymodels/orbital")
```

## Example

Given a fitted workflow

``` r
library(tidymodels)

rec_spec <- recipe(mpg ~ ., data = mtcars) %>%
  step_normalize(all_numeric_predictors())

lm_spec <- linear_reg()

wf_spec <- workflow(rec_spec, lm_spec)

wf_fit <- fit(wf_spec, mtcars)
```

You can predict with it like normal.

``` r
predict(wf_fit, mtcars)
#> # A tibble: 32 × 1
#>    .pred
#>    <dbl>
#>  1  22.6
#>  2  22.1
#>  3  26.3
#>  4  21.2
#>  5  17.7
#>  6  20.4
#>  7  14.4
#>  8  22.5
#>  9  24.4
#> 10  18.7
#> # ℹ 22 more rows
```

We can get the same results by first creating an orbital object

``` r
library(orbital)
orbital_obj <- orbital(wf_fit)
orbital_obj
#> 
#> ── orbital Object ──────────────────────────────────────────────────────────────
#> • cyl = (cyl - 6.1875) / 1.78592164694654
#> • disp = (disp - 230.721875) / 123.938693831382
#> • hp = (hp - 146.6875) / 68.5628684893206
#> • drat = (drat - 3.5965625) / 0.534678736070971
#> • wt = (wt - 3.21725) / 0.978457442989697
#> • qsec = (qsec - 17.84875) / 1.78694323609684
#> • vs = (vs - 0.4375) / 0.504016128774185
#> • am = (am - 0.40625) / 0.498990917235846
#> • gear = (gear - 3.6875) / 0.737804065256947
#> • carb = (carb - 2.8125) / 1.61519997763185
#> • .pred = 20.090625 + (cyl * -0.199023961804222) + (disp * 1.652752216787 ...
#> ────────────────────────────────────────────────────────────────────────────────
#> 11 equations in total.
```

and then “predicting” with it using `predict()` to get the same results

``` r
predict(orbital_obj, as_tibble(mtcars))
#> # A tibble: 32 × 1
#>    .pred
#>    <dbl>
#>  1  22.6
#>  2  22.1
#>  3  26.3
#>  4  21.2
#>  5  17.7
#>  6  20.4
#>  7  14.4
#>  8  22.5
#>  9  24.4
#> 10  18.7
#> # ℹ 22 more rows
```
