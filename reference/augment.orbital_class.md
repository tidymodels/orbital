# Augment using orbital objects

[`augment()`](https://generics.r-lib.org/reference/augment.html) will
add column(s) for predictions to the given data.

## Usage

``` r
# S3 method for class 'orbital_class'
augment(x, new_data, ...)
```

## Arguments

- x:

  An [orbital](https://orbital.tidymodels.org/reference/orbital.md)
  object.

- new_data:

  A data frame or remote database table.

- ...:

  Not currently used.

## Value

A modified data frame or remote database table.

## Details

This function is a shorthand for the following code

    dplyr::bind_cols(
      predict(orbital_obj, new_data),
      new_data
    )

Note that
[`augment()`](https://generics.r-lib.org/reference/augment.html) works
better and safer than above as it also works on data set in data bases.

This function is confirmed to not work work in spark data bases or arrow
tables.

## Examples

``` r
library(workflows)
library(recipes)
#> Loading required package: dplyr
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union
#> 
#> Attaching package: ‘recipes’
#> The following object is masked from ‘package:stats’:
#> 
#>     step
library(parsnip)

rec_spec <- recipe(mpg ~ ., data = mtcars) |>
  step_normalize(all_numeric_predictors())

lm_spec <- linear_reg()

wf_spec <- workflow(rec_spec, lm_spec)

wf_fit <- fit(wf_spec, mtcars)

orbital_obj <- orbital(wf_fit)

augment(orbital_obj, mtcars)
#>       .pred  mpg cyl  disp  hp drat    wt  qsec vs am gear carb
#> 1  22.59951 21.0   6 160.0 110 3.90 2.620 16.46  0  1    4    4
#> 2  22.11189 21.0   6 160.0 110 3.90 2.875 17.02  0  1    4    4
#> 3  26.25064 22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
#> 4  21.23740 21.4   6 258.0 110 3.08 3.215 19.44  1  0    3    1
#> 5  17.69343 18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2
#> 6  20.38304 18.1   6 225.0 105 2.76 3.460 20.22  1  0    3    1
#> 7  14.38626 14.3   8 360.0 245 3.21 3.570 15.84  0  0    3    4
#> 8  22.49601 24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
#> 9  24.41909 22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
#> 10 18.69903 19.2   6 167.6 123 3.92 3.440 18.30  1  0    4    4
#> 11 19.19165 17.8   6 167.6 123 3.92 3.440 18.90  1  0    4    4
#> 12 14.17216 16.4   8 275.8 180 3.07 4.070 17.40  0  0    3    3
#> 13 15.59957 17.3   8 275.8 180 3.07 3.730 17.60  0  0    3    3
#> 14 15.74222 15.2   8 275.8 180 3.07 3.780 18.00  0  0    3    3
#> 15 12.03401 10.4   8 472.0 205 2.93 5.250 17.98  0  0    3    4
#> 16 10.93644 10.4   8 460.0 215 3.00 5.424 17.82  0  0    3    4
#> 17 10.49363 14.7   8 440.0 230 3.23 5.345 17.42  0  0    3    4
#> 18 27.77291 32.4   4  78.7  66 4.08 2.200 19.47  1  1    4    1
#> 19 29.89674 30.4   4  75.7  52 4.93 1.615 18.52  1  1    4    2
#> 20 29.51237 33.9   4  71.1  65 4.22 1.835 19.90  1  1    4    1
#> 21 23.64310 21.5   4 120.1  97 3.70 2.465 20.01  1  0    3    1
#> 22 16.94305 15.5   8 318.0 150 2.76 3.520 16.87  0  0    3    2
#> 23 17.73218 15.2   8 304.0 150 3.15 3.435 17.30  0  0    3    2
#> 24 13.30602 13.3   8 350.0 245 3.73 3.840 15.41  0  0    3    4
#> 25 16.69168 19.2   8 400.0 175 3.08 3.845 17.05  0  0    3    2
#> 26 28.29347 27.3   4  79.0  66 4.08 1.935 18.90  1  1    4    1
#> 27 26.15295 26.0   4 120.3  91 4.43 2.140 16.70  0  1    5    2
#> 28 27.63627 30.4   4  95.1 113 3.77 1.513 16.90  1  1    5    2
#> 29 18.87004 15.8   8 351.0 264 4.22 3.170 14.50  0  1    5    4
#> 30 19.69383 19.7   6 145.0 175 3.62 2.770 15.50  0  1    5    6
#> 31 13.94112 15.0   8 301.0 335 3.54 3.570 14.60  0  1    5    8
#> 32 24.36827 21.4   4 121.0 109 4.11 2.780 18.60  1  1    4    2
```
