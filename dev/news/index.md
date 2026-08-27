# Changelog

## orbital (development version)

### New models

- [`bag_tree()`](https://parsnip.tidymodels.org/reference/bag_tree.html)
  with the `"rpart"` and `"C5.0"` engines is now supported for
  `type = "class"`. These models vote over their ensemble and expose no
  probability, so `type = "prob"` is refused.
  ([\#161](https://github.com/tidymodels/orbital/issues/161))

- [`bart()`](https://parsnip.tidymodels.org/reference/bart.html) with
  the `"dbarts"` engine is now supported for regression. Classification
  is refused, since it uses a probit link that cannot be translated.
  ([\#162](https://github.com/tidymodels/orbital/issues/162))

- [`boost_tree()`](https://parsnip.tidymodels.org/reference/boost_tree.html)
  with the `"C5.0"` engine is now supported for `type = "class"`,
  including multi-trial boosting.
  ([\#161](https://github.com/tidymodels/orbital/issues/161))

- [`boost_tree()`](https://parsnip.tidymodels.org/reference/boost_tree.html)
  with the `"h2o_gbm"` engine, and
  [`rule_fit()`](https://parsnip.tidymodels.org/reference/rule_fit.html)
  with the `"h2o"` engine, are now supported for regression and
  classification. A running H2O cluster is needed to build the orbital
  object, but not to use one afterwards.
  ([\#166](https://github.com/tidymodels/orbital/issues/166))

- [`C5_rules()`](https://parsnip.tidymodels.org/reference/C5_rules.html)
  with the `"C5.0"` engine is now supported for `type = "class"`.
  ([\#161](https://github.com/tidymodels/orbital/issues/161))

- [`decision_tree()`](https://parsnip.tidymodels.org/reference/decision_tree.html)
  with the `"C5.0"` engine is now supported for `type = "class"`. Its
  leaves carry a class label rather than class counts, so
  `type = "prob"` is refused.
  ([\#173](https://github.com/tidymodels/orbital/issues/173))

- [`discrim_linear()`](https://parsnip.tidymodels.org/reference/discrim_linear.html)
  and
  [`discrim_quad()`](https://parsnip.tidymodels.org/reference/discrim_quad.html)
  with the `"MASS"` engine are now supported for `type = "class"` and
  `type = "prob"`.
  ([\#160](https://github.com/tidymodels/orbital/issues/160))

- [`discrim_linear()`](https://parsnip.tidymodels.org/reference/discrim_linear.html)
  with the `"mda"`, `"sda"`, and `"sparsediscrim"` engines is now
  supported for `type = "class"` and `type = "prob"`.
  ([\#163](https://github.com/tidymodels/orbital/issues/163))

- [`linear_reg()`](https://parsnip.tidymodels.org/reference/linear_reg.html)
  with the `"glm"` engine is now supported.
  ([\#160](https://github.com/tidymodels/orbital/issues/160))

- [`logistic_reg()`](https://parsnip.tidymodels.org/reference/logistic_reg.html)
  with the `"LiblineaR"` engine is now supported for `type = "class"`
  and `type = "prob"`.
  ([\#164](https://github.com/tidymodels/orbital/issues/164))

- [`mlp()`](https://parsnip.tidymodels.org/reference/mlp.html) with the
  `"nnet"` engine is now supported for regression and classification.
  ([\#160](https://github.com/tidymodels/orbital/issues/160))

- [`multinom_reg()`](https://parsnip.tidymodels.org/reference/multinom_reg.html)
  with the `"nnet"` engine is now supported for `type = "class"` and
  `type = "prob"`.
  ([\#160](https://github.com/tidymodels/orbital/issues/160))

- [`naive_Bayes()`](https://parsnip.tidymodels.org/reference/naive_Bayes.html)
  with the `"klaR"` and `"naivebayes"` engines is now supported for
  `type = "class"` and `type = "prob"`. Both engines default to
  `usekernel = TRUE`, which fits a kernel density per predictor and has
  no closed form; refit with `usekernel = FALSE` to translate one.
  ([\#163](https://github.com/tidymodels/orbital/issues/163))

- [`null_model()`](https://parsnip.tidymodels.org/reference/null_model.html)
  is now supported for regression and classification.
  ([\#160](https://github.com/tidymodels/orbital/issues/160))

- [`pls()`](https://parsnip.tidymodels.org/reference/pls.html) with the
  `"mixOmics"` engine is now supported for regression and for
  `type = "prob"`. `type = "class"` is refused, since mixOmics assigns a
  class by distance to the class centroid rather than by the largest
  per-level value.
  ([\#163](https://github.com/tidymodels/orbital/issues/163))

- [`rand_forest()`](https://parsnip.tidymodels.org/reference/rand_forest.html)
  with the `"aorsf"` engine is now supported for regression.
  Classification is refused, since aorsf votes across the forest and
  exposes no probability. Note that aorsf splits on observed
  linear-combination values, so a row that lands exactly on a split
  boundary can take the other branch than
  [`predict()`](https://rdrr.io/r/stats/predict.html) did.
  ([\#173](https://github.com/tidymodels/orbital/issues/173))

- [`rand_forest()`](https://parsnip.tidymodels.org/reference/rand_forest.html)
  with the `"partykit"` engine is now supported for regression.
  ([\#161](https://github.com/tidymodels/orbital/issues/161))

- [`rule_fit()`](https://parsnip.tidymodels.org/reference/rule_fit.html)
  with the `"xrf"` engine is now supported for regression and for binary
  classification. Multiclass outcomes are refused, since xrf only fits
  Gaussian and binomial models.
  ([\#164](https://github.com/tidymodels/orbital/issues/164))

- [`svm_linear()`](https://parsnip.tidymodels.org/reference/svm_linear.html)
  with the `"kernlab"` engine is now supported for regression and
  classification.
  ([\#164](https://github.com/tidymodels/orbital/issues/164))

- [`svm_linear()`](https://parsnip.tidymodels.org/reference/svm_linear.html)
  with the `"LiblineaR"` engine is now supported for regression, in
  addition to the `type = "class"` support added in
  [\#159](https://github.com/tidymodels/orbital/issues/159).
  ([\#164](https://github.com/tidymodels/orbital/issues/164))

### Improvements

- `orbital(separate_trees = TRUE)` now works for
  [`rand_forest()`](https://parsnip.tidymodels.org/reference/rand_forest.html)
  with the `"aorsf"` and `"partykit"` engines. The argument used to be
  accepted and silently ignored for every model orbital has no method of
  its own for; it is now honoured for any regression ensemble whose
  per-tree expressions tidypredict exposes.
  ([\#173](https://github.com/tidymodels/orbital/issues/173))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now supports classification models that reach the tidypredict
  fallback, rather than refusing them. This covers multiclass
  probability models such as
  [`MASS::lda()`](https://rdrr.io/pkg/MASS/man/lda.html), models
  returning an uncalibrated decision value such as `LiblineaR` SVMs, and
  models predicting a class label directly such as
  [`C50::C5.0()`](https://topepo.github.io/C5.0/reference/C5.0.html).
  ([\#159](https://github.com/tidymodels/orbital/issues/159))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  refuses `type = "prob"` for models that have no probability to give,
  rather than fabricating one. A decision value is uncalibrated, so
  putting it through a logistic would invent a calibration the model
  does not have.
  ([\#159](https://github.com/tidymodels/orbital/issues/159))

### Bug fixes

- [`estimate_orbital_size()`](https://orbital.tidymodels.org/dev/reference/estimate_orbital_size.md)
  now errors for a workflow whose model it has no estimate for, rather
  than counting that model as zero characters and returning the recipe’s
  size as the whole workflow’s. The model is usually the bulk of the
  expression, so the number it returned could be off by orders of
  magnitude while looking ordinary, and it did not move as the model’s
  hyperparameters changed.
  ([\#167](https://github.com/tidymodels/orbital/issues/167))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now errors for a bare model fit, which was never documented input,
  rather than returning something that looked like a result. A
  regression fit handed in directly took the classification path
  whatever the model was, so `orbital(rpart::rpart(mpg ~ ., mtcars))`
  came back as a character vector named `orbital_tmp_class_name` with no
  error and no warning. Fit the model with
  [`parsnip::fit()`](https://rdrr.io/pkg/generics/man/fit.html), or use
  a workflow, as the documentation has always described.
  ([\#113](https://github.com/tidymodels/orbital/issues/113))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now uses the model’s own class order for binary probabilities, rather
  than assuming it matches the order of the outcome’s factor levels.
  Every engine but h2o orders them the same way, so only h2o models were
  affected, and only when the outcome’s levels were not in sorted order;
  for those both probability columns were swapped and the class
  inverted. ([\#166](https://github.com/tidymodels/orbital/issues/166))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now returns the correct classes for
  [`svm_linear()`](https://parsnip.tidymodels.org/reference/svm_linear.html)
  models with the `"LiblineaR"` engine. The sign of the decision value
  was read as meaning the second outcome level, but LiblineaR orients it
  by its own class order, which need not match the order of the
  outcome’s factor levels. When the two disagreed every class was
  inverted. ([\#164](https://github.com/tidymodels/orbital/issues/164))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now returns the correct classes for
  [`svm_linear()`](https://parsnip.tidymodels.org/reference/svm_linear.html)
  models with the `"kernlab"` engine. kernlab classifies by the sign of
  its decision function and calibrates its probabilities separately, so
  cutting those probabilities at 0.5 disagreed with the model for rows
  near the boundary.
  ([\#164](https://github.com/tidymodels/orbital/issues/164))

- Binary `earth()` classification models now generate
  `1 / (1 + exp(-x))` rather than the equivalent `1 - 1 / (1 + exp(x))`.
  Predictions are unchanged.
  ([\#158](https://github.com/tidymodels/orbital/issues/158))

- `orbital(separate_trees = TRUE)` now returns `NA` for rows with a
  missing predictor, matching what `separate_trees = FALSE` has always
  returned. The individual tree expressions fall through to their
  default branch when a split variable is `NA`, so such rows previously
  received a confident-looking prediction computed from no usable data.
  ([\#158](https://github.com/tidymodels/orbital/issues/158))

- `orbital(separate_trees = TRUE)` now applies CatBoost’s scale and bias
  to binary classification models. The regression path applied them and
  the binary path did not, so the two disagreed with
  `separate_trees = FALSE` whenever a model carried a non-default scale
  or bias. ([\#158](https://github.com/tidymodels/orbital/issues/158))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  no longer falls back to tidypredict when one of its own model methods
  errors. An error in a native method was previously caught and silently
  replaced with a tidypredict result, so a bug could still produce an
  answer. Whether a native method exists is now checked directly, and
  errors from it propagate.
  ([\#156](https://github.com/tidymodels/orbital/issues/156))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now errors for classification models that reach the tidypredict
  fallback, instead of returning prediction columns named after
  tidypredict’s internals.
  ([\#156](https://github.com/tidymodels/orbital/issues/156))

- [`print()`](https://rdrr.io/r/base/print.html) no longer corrupts
  numbers when rounding them for display. Numbers such as
  `6.75044994983228` and `-0.0901719835820594` were printed as `6.750.5`
  and `-017198`. Only the printed output was affected; the expressions
  themselves were always correct.
  ([\#155](https://github.com/tidymodels/orbital/issues/155))

## orbital 0.5.1

CRAN release: 2026-03-13

### Improvements

- [`estimate_orbital_size()`](https://orbital.tidymodels.org/dev/reference/estimate_orbital_size.md)
  is a new function that quickly estimates the character count of the
  orbital expression for a model without generating it.
  ([\#144](https://github.com/tidymodels/orbital/issues/144))

### Bug fixes

- [`step_dummy()`](https://recipes.tidymodels.org/reference/step_dummy.html)
  and
  [`step_indicate_na()`](https://recipes.tidymodels.org/reference/step_indicate_na.html)
  now generate SQL compatible with Snowflake and other databases that
  don’t support casting booleans directly to numeric types.
  ([\#145](https://github.com/tidymodels/orbital/issues/145))

## orbital 0.5.0

CRAN release: 2026-02-27

### New models

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works with `boost_tree(engine = "catboost")` models for numeric,
  class, and probability predictions.
  ([\#90](https://github.com/tidymodels/orbital/issues/90))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works with `boost_tree(engine = "lightgbm")` models for numeric,
  class, and probability predictions.
  ([\#89](https://github.com/tidymodels/orbital/issues/89))

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  now works with `decision_tree(engine = "rpart")` models for numeric,
  class, and probability predictions.
  ([\#128](https://github.com/tidymodels/orbital/issues/128))

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

### Improvements

- [`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
  gains a `separate_trees` argument for tree ensemble models (xgboost,
  lightgbm, catboost, ranger, randomForest). When `TRUE`, each tree is
  emitted as a separate intermediate column before being summed, which
  can enable parallel evaluation in columnar databases like DuckDB,
  Snowflake, and BigQuery. For models with many trees, the final
  summation is automatically batched in groups of 50 to avoid expression
  depth limits in databases. See the “Separate trees” vignette for
  details. ([\#105](https://github.com/tidymodels/orbital/issues/105))

- Added support for
  [`step_spline_b()`](https://recipes.tidymodels.org/reference/step_spline_b.html),
  [`step_spline_convex()`](https://recipes.tidymodels.org/reference/step_spline_convex.html),
  [`step_spline_monotone()`](https://recipes.tidymodels.org/reference/step_spline_monotone.html),
  [`step_spline_natural()`](https://recipes.tidymodels.org/reference/step_spline_natural.html),
  and
  [`step_spline_nonnegative()`](https://recipes.tidymodels.org/reference/step_spline_nonnegative.html)
  from the recipes package.
  ([\#99](https://github.com/tidymodels/orbital/issues/99))

- [`step_YeoJohnson()`](https://recipes.tidymodels.org/reference/step_YeoJohnson.html)
  is now supported.
  ([\#96](https://github.com/tidymodels/orbital/issues/96))

- Binary classification probability predictions now generate cleaner
  code by having the second probability reference the first (e.g.,
  `.pred_1 = 1 - .pred_0`) instead of duplicating the full expression.
  ([\#100](https://github.com/tidymodels/orbital/issues/100))

- New “Database deployment” vignette shows how to deploy predictions to
  a database as tables or views.
  ([\#74](https://github.com/tidymodels/orbital/issues/74))

- New “SQL size” vignette documents how model type and hyperparameters
  affect generated SQL size, and shows how to jointly tune for
  predictive performance and SQL complexity.

### Bug fixes

- All numeric values embedded in SQL expressions now use full IEEE 754
  double precision (17 significant digits) to ensure exact round-trip
  accuracy between R and database predictions. This prevents subtle
  numerical drift in regularized model coefficients, normalized
  features, and tree split values.
  ([\#138](https://github.com/tidymodels/orbital/issues/138))

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

- [`augment()`](https://rdrr.io/pkg/generics/man/augment.html) method
  for
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
