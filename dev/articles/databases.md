# Using Databases

## Setup

We start by loading our packages and creating a simple fitted workflow
using `mtcars`.

``` r
library(orbital)
library(recipes)
library(parsnip)
library(workflows)
```

``` r
rec_spec <- recipe(mpg ~ disp, data = mtcars) |>
  step_impute_mean(all_numeric_predictors()) |>
  step_normalize(all_numeric_predictors())

lm_spec <- linear_reg()

wf_spec <- workflow(rec_spec, lm_spec)
wf_fit <- fit(wf_spec, data = mtcars)
```

then create our orbital object.

``` r
orbital_obj <- orbital(wf_fit)
orbital_obj
```

## SQL

``` r
library(DBI)
library(RSQLite)

con_sqlite <- dbConnect(SQLite(), path = ":memory:")
mtcars_sqlite <- copy_to(con_sqlite, mtcars, name = "mtcars_table")

predict(orbital_obj, mtcars_sqlite)
#> # Source:   SQL [?? x 1]
#> # Database: sqlite 3.51.2 []
#>    .pred
#>    <dbl>
#>  1  23.0
#>  2  23.0
#>  3  25.1
#>  4  19.0
#>  5  14.8
#>  6  20.3
#>  7  14.8
#>  8  23.6
#>  9  23.8
#> 10  22.7
#> # ℹ more rows
```

``` r
predict(orbital_obj, mtcars_sqlite) |>
  collect()
#> # A tibble: 32 × 1
#>    .pred
#>    <dbl>
#>  1  23.0
#>  2  23.0
#>  3  25.1
#>  4  19.0
#>  5  14.8
#>  6  20.3
#>  7  14.8
#>  8  23.6
#>  9  23.8
#> 10  22.7
#> # ℹ 22 more rows
```

## Spark

``` r
library(sparklyr)

con_spark <- spark_connect(master = "local")
mtcars_spark <- copy_to(con_spark, mtcars, overwrite = TRUE)

predict(orbital_obj, mtcars_spark)
#> # Source:   SQL [?? x 1]
#> # Database: spark_connection
#>    .pred
#>    <dbl>
#>  1  23.0
#>  2  23.0
#>  3  25.1
#>  4  19.0
#>  5  14.8
#>  6  20.3
#>  7  14.8
#>  8  23.6
#>  9  23.8
#> 10  22.7
#> # ℹ more rows
```

``` r
predict(orbital_obj, mtcars_spark) |>
  collect()
#> # A tibble: 32 × 1
#>    .pred
#>    <dbl>
#>  1  23.0
#>  2  23.0
#>  3  25.1
#>  4  19.0
#>  5  14.8
#>  6  20.3
#>  7  14.8
#>  8  23.6
#>  9  23.8
#> 10  22.7
#> # ℹ 22 more rows
```

## duckdb

``` r
library(duckdb)

con_duckdb <- dbConnect(duckdb(dbdir = ":memory:"))
mtcars_duckdb <- dplyr::copy_to(con_duckdb, mtcars)

predict(orbital_obj, mtcars_duckdb)
#> # Source:   SQL [?? x 1]
#> # Database: DuckDB 1.4.4 [unknown@Linux 6.14.0-1017-azure:R 4.5.2/:memory:]
#>    .pred
#>    <dbl>
#>  1  23.0
#>  2  23.0
#>  3  25.1
#>  4  19.0
#>  5  14.8
#>  6  20.3
#>  7  14.8
#>  8  23.6
#>  9  23.8
#> 10  22.7
#> # ℹ more rows
```

``` r
predict(orbital_obj, mtcars_duckdb) |>
  collect()
#> # A tibble: 32 × 1
#>    .pred
#>    <dbl>
#>  1  23.0
#>  2  23.0
#>  3  25.1
#>  4  19.0
#>  5  14.8
#>  6  20.3
#>  7  14.8
#>  8  23.6
#>  9  23.8
#> 10  22.7
#> # ℹ 22 more rows
```

## arrow

``` r
library(arrow)
mtcars_arrow <- as_arrow_table(mtcars)

predict(orbital_obj, mtcars_arrow)
#> Table (query)
#> .pred: double (add_checked(20.090625, multiply_checked(divide(cast(subtract_checked(if_else(is_null(disp, {nan_is_null=true}), 230.721875, disp), 230.721875), {to_type=double, allow_int_overflow=false, allow_time_truncate=false, allow_time_overflow=false, allow_decimal_truncate=false, allow_float_truncate=false, allow_invalid_utf8=false}), cast(123.938693831382, {to_type=double, allow_int_overflow=false, allow_time_truncate=false, allow_time_overflow=false, allow_decimal_truncate=false, allow_float_truncate=false, allow_invalid_utf8=false})), -5.10814813429143)))
#> 
#> See $.data for the source Arrow object
```

``` r
predict(orbital_obj, mtcars_arrow) |>
  collect()
#> # A tibble: 32 × 1
#>    .pred
#>    <dbl>
#>  1  23.0
#>  2  23.0
#>  3  25.1
#>  4  19.0
#>  5  14.8
#>  6  20.3
#>  7  14.8
#>  8  23.6
#>  9  23.8
#> 10  22.7
#> # ℹ 22 more rows
```
