# Database deployment

Once you’ve created an orbital object, you can deploy it to a database
by creating a TABLE or VIEW. Both approaches use the same underlying SQL
generation, but they have different tradeoffs:

- **Tables** store pre-computed predictions. They’re fast to query and
  work well for large datasets or complex models. The tradeoff is that
  predictions become stale when data changes, so you’ll need a scheduled
  job to refresh them.

- **Views** compute predictions on-the-fly each time they’re queried.
  Predictions are always fresh, but query performance depends on model
  complexity and data size. Views are useful for prototyping, smaller
  datasets, or when you need real-time predictions.

## Setup

We start by loading our packages and creating a simple fitted workflow.

``` r
library(orbital)
library(recipes)
library(parsnip)
library(workflows)
library(dplyr)
library(DBI)
library(duckdb)
```

``` r
rec_spec <- recipe(mpg ~ disp + wt + hp, data = mtcars) |>
  step_normalize(all_numeric_predictors())

lm_spec <- linear_reg()

wf_spec <- workflow(rec_spec, lm_spec)
wf_fit <- fit(wf_spec, data = mtcars)
```

Then create our orbital object.

``` r
orbital_obj <- orbital(wf_fit)
orbital_obj
```

## Connect to a database

We’ll use DuckDB as our example database since it runs in-memory and
requires no external setup. The same pattern works with other databases
like PostgreSQL, Snowflake, SQL Server, and Spark.

``` r
con <- dbConnect(duckdb(dbdir = ":memory:"))
mtcars_db <- copy_to(con, mtcars, name = "mtcars_data")
```

## Generating the prediction SQL

Both tables and views start the same way: use
[`orbital_inline()`](https://orbital.tidymodels.org/dev/reference/orbital_inline.md)
with
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
to apply predictions to a database table, then extract the generated
SQL.

``` r
# Apply predictions to the table
predictions <- mtcars_db |>
  mutate(!!!orbital_inline(orbital_obj))

# View the lazy query
predictions
#> # Source:   SQL [?? x 12]
#> # Database: DuckDB 1.4.4 [unknown@Linux 6.14.0-1017-azure:R 4.5.2/:memory:]
#>      mpg   cyl    disp     hp  drat       wt  qsec    vs    am  gear
#>    <dbl> <dbl>   <dbl>  <dbl> <dbl>    <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1  21       6 -0.571  -0.535  3.9  -0.610    16.5     0     1     4
#>  2  21       6 -0.571  -0.535  3.9  -0.350    17.0     0     1     4
#>  3  22.8     4 -0.990  -0.783  3.85 -0.917    18.6     1     1     4
#>  4  21.4     6  0.220  -0.535  3.08 -0.00230  19.4     1     0     3
#>  5  18.7     8  1.04    0.413  3.15  0.228    17.0     0     0     3
#>  6  18.1     6 -0.0462 -0.608  2.76  0.248    20.2     1     0     3
#>  7  14.3     8  1.04    1.43   3.21  0.361    15.8     0     0     3
#>  8  24.4     4 -0.678  -1.24   3.69 -0.0278   20       1     0     4
#>  9  22.8     4 -0.726  -0.754  3.92 -0.0687   22.9     1     0     4
#> 10  19.2     6 -0.509  -0.345  3.92  0.228    18.3     1     0     4
#> # ℹ more rows
#> # ℹ 2 more variables: carb <dbl>, .pred <dbl>
```

We can extract the SQL query using
[`dbplyr::remote_query()`](https://dbplyr.tidyverse.org/reference/remote_name.html).

``` r
library(dbplyr)
generated_sql <- remote_query(predictions)
generated_sql
#> <SQL> SELECT
#>   q01.*,
#>   ((20.090625 + (disp * -0.116131681667974)) + (wt * -3.71900968057122)) + (hp * -2.13618249713439) AS ".pred"
#> FROM (
#>   SELECT
#>     mpg,
#>     cyl,
#>     (disp - 230.721875) / 123.938693831382 AS disp,
#>     (hp - 146.6875) / 68.5628684893206 AS hp,
#>     drat,
#>     (wt - 3.21725) / 0.978457442989697 AS wt,
#>     qsec,
#>     vs,
#>     am,
#>     gear,
#>     carb
#>   FROM mtcars_data
#> ) q01
```

## Creating a table

Tables store predictions at a point in time. They’re fast to query and
work well with large datasets or complex models.

``` r
table_name <- "mtcars_predictions"
table_sql <- paste("CREATE OR REPLACE TABLE", table_name, "AS", generated_sql)
dbExecute(con, table_sql)
#> [1] 32
```

``` r
tbl(con, table_name) |>
  collect()
#> # A tibble: 32 × 12
#>      mpg   cyl    disp     hp  drat       wt  qsec    vs    am  gear
#>    <dbl> <dbl>   <dbl>  <dbl> <dbl>    <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1  21       6 -0.571  -0.535  3.9  -0.610    16.5     0     1     4
#>  2  21       6 -0.571  -0.535  3.9  -0.350    17.0     0     1     4
#>  3  22.8     4 -0.990  -0.783  3.85 -0.917    18.6     1     1     4
#>  4  21.4     6  0.220  -0.535  3.08 -0.00230  19.4     1     0     3
#>  5  18.7     8  1.04    0.413  3.15  0.228    17.0     0     0     3
#>  6  18.1     6 -0.0462 -0.608  2.76  0.248    20.2     1     0     3
#>  7  14.3     8  1.04    1.43   3.21  0.361    15.8     0     0     3
#>  8  24.4     4 -0.678  -1.24   3.69 -0.0278   20       1     0     4
#>  9  22.8     4 -0.726  -0.754  3.92 -0.0687   22.9     1     0     4
#> 10  19.2     6 -0.509  -0.345  3.92  0.228    18.3     1     0     4
#> # ℹ 22 more rows
#> # ℹ 2 more variables: carb <dbl>, .pred <dbl>
```

The table contains predictions computed at the time it was created. To
keep predictions fresh, you would schedule a job (e.g., daily or hourly)
to drop and recreate the table, or use an incremental update strategy
that only scores new rows.

## Creating a view

Views compute predictions on-the-fly, providing always-fresh results
without needing a refresh job.

``` r
view_name <- "mtcars_predictions_view"
view_sql <- paste("CREATE OR REPLACE VIEW", view_name, "AS", generated_sql)
dbExecute(con, view_sql)
#> [1] 0
```

``` r
tbl(con, view_name) |>
  collect()
#> # A tibble: 32 × 12
#>      mpg   cyl    disp     hp  drat       wt  qsec    vs    am  gear
#>    <dbl> <dbl>   <dbl>  <dbl> <dbl>    <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1  21       6 -0.571  -0.535  3.9  -0.610    16.5     0     1     4
#>  2  21       6 -0.571  -0.535  3.9  -0.350    17.0     0     1     4
#>  3  22.8     4 -0.990  -0.783  3.85 -0.917    18.6     1     1     4
#>  4  21.4     6  0.220  -0.535  3.08 -0.00230  19.4     1     0     3
#>  5  18.7     8  1.04    0.413  3.15  0.228    17.0     0     0     3
#>  6  18.1     6 -0.0462 -0.608  2.76  0.248    20.2     1     0     3
#>  7  14.3     8  1.04    1.43   3.21  0.361    15.8     0     0     3
#>  8  24.4     4 -0.678  -1.24   3.69 -0.0278   20       1     0     4
#>  9  22.8     4 -0.726  -0.754  3.92 -0.0687   22.9     1     0     4
#> 10  19.2     6 -0.509  -0.345  3.92  0.228    18.3     1     0     4
#> # ℹ 22 more rows
#> # ℹ 2 more variables: carb <dbl>, .pred <dbl>
```

Keep in mind that the prediction SQL runs every time the view is
queried. For complex models or large tables, this can be slow.

## Selecting specific columns

In production, you often want to include only the prediction column and
an identifier column, rather than all the intermediate calculations.

``` r
# Select only ID-like columns and the prediction
predictions_slim <- mtcars_db |>
  mutate(row_id = row_number(), !!!orbital_inline(orbital_obj)) |>
  select(row_id, .pred)

slim_sql <- remote_query(predictions_slim)

table_sql <- paste("CREATE OR REPLACE TABLE mtcars_pred_slim AS", slim_sql)
dbExecute(con, table_sql)
#> [1] 32

tbl(con, "mtcars_pred_slim") |>
  collect()
#> # A tibble: 32 × 2
#>    row_id .pred
#>     <dbl> <dbl>
#>  1      1  23.6
#>  2      2  22.6
#>  3      3  25.3
#>  4      4  21.2
#>  5      5  18.2
#>  6      6  20.5
#>  7      7  15.6
#>  8      8  22.9
#>  9      9  22.0
#> 10     10  20.0
#> # ℹ 22 more rows
```

## Database-specific considerations

Consider versioning your prediction tables or views (e.g., `model_v1`,
`model_v2`) so you can compare predictions across model versions or roll
back if needed.

The pattern shown above works across most SQL databases, but there are
some differences to be aware of:

- **Column naming**: Some databases (e.g., Databricks) don’t allow
  column names with dots. Use `orbital(wf_fit, prefix = "pred")` to
  generate columns named `pred` instead of `.pred`.
- **SQL Server**: Uses `CREATE OR ALTER VIEW` instead of
  `CREATE OR REPLACE VIEW` (requires SQL Server 2016 or later).
- **SQLite**: Uses `DROP VIEW IF EXISTS` followed by `CREATE VIEW` since
  it doesn’t support `CREATE OR REPLACE`.
- **Function support**: Complex models using functions like
  [`log()`](https://rdrr.io/r/base/Log.html),
  [`exp()`](https://rdrr.io/r/base/Log.html), or probability functions
  may behave differently across databases. Always test your generated
  SQL on your target database.
- **Query complexity**: Very large models (e.g., tree ensembles with
  many trees) may generate SQL that exceeds database-specific limits on
  expression depth or query length.

This article covers the basics. Production deployments often involve
additional considerations like access controls, monitoring, logging, and
integration with your organization’s data infrastructure.
