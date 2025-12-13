# Package index

## Create orbital objects

Turn a fitted workflow, parsnip, or recipes object into an orbital
object. This will almost always be the first function you use.

- [`orbital()`](https://orbital.tidymodels.org/reference/orbital.md) :
  Turn tidymodels objects into orbital objects

## Prediction

An orbital object can be predicted with, using data.frames or
connections to data bases.

- [`predict(`*`<orbital_class>`*`)`](https://orbital.tidymodels.org/reference/predict.orbital_class.md)
  : Prediction using orbital objects
- [`augment(`*`<orbital_class>`*`)`](https://orbital.tidymodels.org/reference/augment.orbital_class.md)
  : Augment using orbital objects

## Code generation

An orbital object can be turned into code itself that produces the same
output as predicting would.

- [`orbital_dt()`](https://orbital.tidymodels.org/reference/orbital_dt.md)
  : Convert to data.table code
- [`orbital_inline()`](https://orbital.tidymodels.org/reference/orbital_inline.md)
  : Convert orbital objects to quosures
- [`orbital_sql()`](https://orbital.tidymodels.org/reference/orbital_sql.md)
  : Convert to SQL code
- [`orbital_r_fun()`](https://orbital.tidymodels.org/reference/orbital_r_fun.md)
  : Turn orbital object into a R function

## Read and Write

Reading and writing orbital objects to json files for easy storage.

- [`orbital_json_read()`](https://orbital.tidymodels.org/reference/orbital_json_read.md)
  : Read orbital json file
- [`orbital_json_write()`](https://orbital.tidymodels.org/reference/orbital_json_write.md)
  : Save orbital object as json file
