
<!-- README.md is generated from README.Rmd. Please edit that file -->

# orbital <a href="https://orbital.tidymodels.org"><img src="man/figures/logo.png" align="right" height="138" alt="orbital website" /></a>

<!-- badges: start -->

[![R-CMD-check](https://github.com/tidymodels/orbital/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/tidymodels/orbital/actions/workflows/R-CMD-check.yaml)
[![CRAN
status](https://www.r-pkg.org/badges/version/orbital)](https://CRAN.R-project.org/package=orbital)
[![Codecov test
coverage](https://codecov.io/gh/tidymodels/orbital/graph/badge.svg)](https://app.codecov.io/gh/tidymodels/orbital)
[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
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

rec_spec <- recipe(mpg ~ ., data = mtcars) |>
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
#> • .pred = 20.09062 + (cyl * -0.199024) + (disp * 1.652752) + (hp * -1.472 ...
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

you can also predict in most SQL databases

``` r
library(DBI)
library(RSQLite)

con <- dbConnect(SQLite(), path = ":memory:")
db_mtcars <- copy_to(con, mtcars)

predict(orbital_obj, db_mtcars)
#> # Source:   SQL [?? x 1]
#> # Database: sqlite 3.51.1 []
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
#> # ℹ more rows
```

and spark databases

``` r
library(sparklyr)
sc <- spark_connect(master = "local")

sc_mtcars <- copy_to(sc, mtcars, overwrite = TRUE)

predict(orbital_obj, sc_mtcars)
#> # Source:   SQL [?? x 1]
#> # Database: spark_connection
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
#> # ℹ more rows
```

## Supported models and recipes steps

Full list of supported models and recipes steps can be found here:
`vignette("supported-models")`.

## Python Version

We have created a [python version of
orbital](https://posit-dev.github.io/orbital/) that works on on fitted
scikit learn models.

## contributing

This project is released with a [Contributor Code of
Conduct](https://github.com/tidymodels/orbital/blob/main/.github/CODE_OF_CONDUCT.md).
By contributing to this project, you agree to abide by its terms.

- For questions and discussions about tidymodels packages, modeling, and
  machine learning, please [post on Posit
  Community](https://forum.posit.co/new-topic?category_id=15&tags=tidymodels,question).

- If you think you have encountered a bug, please [submit an
  issue](https://github.com/tidymodels/orbital/issues).

- Either way, learn how to create and share a
  [reprex](https://reprex.tidyverse.org/articles/articles/learn-reprex.html)
  (a minimal, reproducible example), to clearly communicate about your
  code.

- Check out further details on [contributing guidelines for tidymodels
  packages](https://www.tidymodels.org/contribute/) and [how to get
  help](https://www.tidymodels.org/help/).
