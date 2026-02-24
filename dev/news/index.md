# Changelog

## orbital (development version)

- Binary classification probability predictions now generate cleaner
  code by having the second probability reference the first (e.g.,
  `.pred_1 = 1 - .pred_0`) instead of duplicating the full expression.
  ([\#100](https://github.com/tidymodels/orbital/issues/100))

- New `vignette("sql-size")` documents how model type and
  hyperparameters affect generated SQL size, and shows how to jointly
  tune for predictive performance and SQL complexity.

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  gains a `separate_trees` argument for tree ensemble models (xgboost,
  lightgbm, catboost, ranger, randomForest). When `TRUE`, each tree is
  emitted as a separate intermediate column before being summed, which
  can enable parallel evaluation in columnar databases like DuckDB,
  Snowflake, and BigQuery. For models with many trees, the final
  summation is automatically batched in groups of 50 to avoid expression
  depth limits in databases. See
  [`vignette("separate-trees")`](https://orbital.tidymodels.org/dev/articles/separate-trees.md)
  for details.
  ([\#105](https://github.com/tidymodels/orbital/issues/105))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works with `boost_tree(engine = "catboost")` models for numeric,
  class, and probability predictions.
  ([\#90](https://github.com/tidymodels/orbital/issues/90))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works with `decision_tree(engine = "rpart")` models for numeric,
  class, and probability predictions.
  ([\#128](https://github.com/tidymodels/orbital/issues/128))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works with `boost_tree(engine = "lightgbm")` models for numeric,
  class, and probability predictions.
  ([\#89](https://github.com/tidymodels/orbital/issues/89))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works with `mars(engine = "earth")` models for class and
  probability predictions.
  ([\#127](https://github.com/tidymodels/orbital/issues/127))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works with `multinom_reg(engine = "glmnet")` models for class and
  probability predictions.
  ([\#127](https://github.com/tidymodels/orbital/issues/127))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works with `rand_forest(engine = "randomForest")` models for class
  and probability predictions.
  ([\#127](https://github.com/tidymodels/orbital/issues/127))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works with `rand_forest(engine = "ranger")` models for class and
  probability predictions.
  ([\#127](https://github.com/tidymodels/orbital/issues/127))

## orbital 0.4.1

CRAN release: 2025-12-13

- Make work with new versions of xgboost.
  ([\#119](https://github.com/tidymodels/orbital/issues/119))

## orbital 0.4.0

CRAN release: 2025-12-04

- Added support for tailor package and its integration into workflows.
  The following adjustments have gained
  [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  support. ([\#103](https://github.com/tidymodels/orbital/issues/103))

  - `adjust_equivocal_zone()`
  - `adjust_numeric_range()`
  - `adjust_predictions_custom()`
  - `adjust_probability_threshold()`

- Added
  [`show_query()`](https://dplyr.tidyverse.org/reference/explain.html)
  method for orbital objects.
  ([\#106](https://github.com/tidymodels/orbital/issues/106))

- Fixed printing bug where output would get malformed if coefficients
  had similarities.
  ([\#115](https://github.com/tidymodels/orbital/issues/115))

## orbital 0.3.1

CRAN release: 2025-08-30

- Fixed bug where PCA steps didn’t work if they were trained with more
  than 99 predictors.
  ([\#82](https://github.com/tidymodels/orbital/issues/82))

- `step_pca_sparse()` no longer generate code with terms with 0 in them.
  ([\#51](https://github.com/tidymodels/orbital/issues/51))

- Fixed bugs in all PCA steps where an error occurred depending on which
  predictors were selected.
  ([\#52](https://github.com/tidymodels/orbital/issues/52))

- Fixed bug where large PCA results wouldn’t work with data bases.
  ([\#84](https://github.com/tidymodels/orbital/issues/84))

## orbital 0.3.0

CRAN release: 2024-12-22

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  has gained `type` argument to change prediction type.
  ([\#66](https://github.com/tidymodels/orbital/issues/66))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works with `logistic_reg(engine = "glm")` models for class
  prediction and probability predictions.
  ([\#62](https://github.com/tidymodels/orbital/issues/62),
  [\#66](https://github.com/tidymodels/orbital/issues/66))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works with `boost_tree(engine = "xgboost")` models for class
  prediction and probability predictions.
  ([\#71](https://github.com/tidymodels/orbital/issues/71))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works with `decision_tree(engine = "partykit")` models for class
  prediction and probability predictions.
  ([\#77](https://github.com/tidymodels/orbital/issues/77))

- [`augment()`](https://generics.r-lib.org/reference/augment.html)
  method for
  [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  object have been added.
  ([\#55](https://github.com/tidymodels/orbital/issues/55))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  gained `prefix` argument to allow for renaming of prediction columns.
  ([\#59](https://github.com/tidymodels/orbital/issues/59))

## orbital 0.2.0

CRAN release: 2024-07-28

- Support for
  [`step_dummy()`](https://recipes.tidymodels.org/reference/step_dummy.html),
  [`step_impute_mean()`](https://recipes.tidymodels.org/reference/step_impute_mean.html),
  [`step_impute_median()`](https://recipes.tidymodels.org/reference/step_impute_median.html),
  [`step_impute_mode()`](https://recipes.tidymodels.org/reference/step_impute_mode.html),
  [`step_unknown()`](https://recipes.tidymodels.org/reference/step_unknown.html),
  [`step_novel()`](https://recipes.tidymodels.org/reference/step_novel.html),
  [`step_other()`](https://recipes.tidymodels.org/reference/step_other.html),
  [`step_BoxCox()`](https://recipes.tidymodels.org/reference/step_BoxCox.html),
  [`step_inverse()`](https://recipes.tidymodels.org/reference/step_inverse.html),
  [`step_mutate()`](https://recipes.tidymodels.org/reference/step_mutate.html),
  [`step_sqrt()`](https://recipes.tidymodels.org/reference/step_sqrt.html),
  [`step_indicate_na()`](https://recipes.tidymodels.org/reference/step_indicate_na.html),
  [`step_range()`](https://recipes.tidymodels.org/reference/step_range.html),
  [`step_intercept()`](https://recipes.tidymodels.org/reference/step_intercept.html),
  [`step_ratio()`](https://recipes.tidymodels.org/reference/step_ratio.html),
  [`step_lag()`](https://recipes.tidymodels.org/reference/step_lag.html),
  [`step_log()`](https://recipes.tidymodels.org/reference/step_log.html),
  [`step_rename()`](https://recipes.tidymodels.org/reference/step_rename.html)
  has been added.
  ([\#17](https://github.com/tidymodels/orbital/issues/17))

- Support for `step_upsample()`, `step_smote()`, `step_smotenc()`,
  `step_bsmote()`, `step_adasyn()`, `step_rose()`, `step_downsample()`,
  `step_nearmiss()`, and `step_tomek()` has been added.
  ([\#21](https://github.com/tidymodels/orbital/issues/21))

- Support for
  [`step_bin2factor()`](https://recipes.tidymodels.org/reference/step_bin2factor.html),
  [`step_discretize()`](https://recipes.tidymodels.org/reference/step_discretize.html),
  `step_lencode_mixed()`, `step_lencode_glm()`, `step_lencode_bayes()`
  has been added.
  ([\#22](https://github.com/tidymodels/orbital/issues/22))

- Support for `step_pca_sparse()`, `step_pca_sparse_bayes()` and
  `step_pca_truncated()` as been added.
  ([\#23](https://github.com/tidymodels/orbital/issues/23))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works on
  [`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html)
  objects. ([\#13](https://github.com/tidymodels/orbital/issues/13))

- `orbital_predict()` has been removed and replaced with the more
  idiomatic [`predict()`](https://rdrr.io/r/stats/predict.html) method.
  ([\#10](https://github.com/tidymodels/orbital/issues/10))

## orbital 0.1.0

CRAN release: 2024-07-01

- Initial CRAN submission.
