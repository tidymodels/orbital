# orbital (development version)

* Binary classification probability predictions now generate cleaner code by having the second probability reference the first (e.g., `.pred_1 = 1 - .pred_0`) instead of duplicating the full expression. (#100)

* New `vignette("sql-size")` documents how model type and hyperparameters affect generated SQL size, and shows how to jointly tune for predictive performance and SQL complexity.

* `orbital()` gains a `separate_trees` argument for tree ensemble models (xgboost, lightgbm, catboost, ranger, randomForest). When `TRUE`, each tree is emitted as a separate intermediate column before being summed, which can enable parallel evaluation in columnar databases like DuckDB, Snowflake, and BigQuery. For models with many trees, the final summation is automatically batched in groups of 50 to avoid expression depth limits in databases. See `vignette("separate-trees")` for details. (#105)

* `orbital()` now works with `boost_tree(engine = "catboost")` models for numeric, class, and probability predictions. (#90)

* `orbital()` now works with `decision_tree(engine = "rpart")` models for numeric, class, and probability predictions. (#128)

* `orbital()` now works with `boost_tree(engine = "lightgbm")` models for numeric, class, and probability predictions. (#89)

* `orbital()` now works with `mars(engine = "earth")` models for class and probability predictions. (#127)

* `orbital()` now works with `multinom_reg(engine = "glmnet")` models for class and probability predictions. (#127)

* `orbital()` now works with `rand_forest(engine = "randomForest")` models for class and probability predictions. (#127)

* `orbital()` now works with `rand_forest(engine = "ranger")` models for class and probability predictions. (#127)

* `step_YeoJohnson()` is now supported. (#96)

# orbital 0.4.1

* Make work with new versions of xgboost. (#119)

# orbital 0.4.0

* Added support for tailor package and its integration into workflows. The following adjustments have gained `orbital()` support. (#103)
    - `adjust_equivocal_zone()`
    - `adjust_numeric_range()`
    - `adjust_predictions_custom()`
    - `adjust_probability_threshold()`

* Added `show_query()` method for orbital objects. (#106)

* Fixed printing bug where output would get malformed if coefficients had similarities. (#115)

# orbital 0.3.1

* Fixed bug where PCA steps didn't work if they were trained with more than 99 predictors. (#82)

* `step_pca_sparse()` no longer generate code with terms with 0 in them. (#51)

* Fixed bugs in all PCA steps where an error occurred depending on which predictors were selected. (#52)

* Fixed bug where large PCA results wouldn't work with data bases. (#84)

# orbital 0.3.0

* `orbital()` has gained `type` argument to change prediction type. (#66)

* `orbital()` now works with `logistic_reg(engine = "glm")` models for class prediction and probability predictions. (#62, #66)

* `orbital()` now works with `boost_tree(engine = "xgboost")` models for class prediction and probability predictions. (#71)

* `orbital()` now works with `decision_tree(engine = "partykit")` models for class prediction and probability predictions. (#77)

* `augment()` method for `orbital()` object have been added. (#55)

* `orbital()` gained `prefix` argument to allow for renaming of prediction columns. (#59)

# orbital 0.2.0

* Support for `step_dummy()`,  `step_impute_mean()`, `step_impute_median()`, `step_impute_mode()`,  `step_unknown()`, `step_novel()`, `step_other()`, `step_BoxCox()`, `step_inverse()`, `step_mutate()`, `step_sqrt()`, `step_indicate_na()`, `step_range()`, `step_intercept()`, `step_ratio()`, `step_lag()`, `step_log()`, `step_rename()` has been added. (#17)

* Support for `step_upsample()`, `step_smote()`, `step_smotenc()`, `step_bsmote()`, `step_adasyn()`, `step_rose()`, `step_downsample()`, `step_nearmiss()`, and `step_tomek()` has been added. (#21)

* Support for `step_bin2factor()`, `step_discretize()`, `step_lencode_mixed()`, `step_lencode_glm()`, `step_lencode_bayes()` has been added. (#22)

* Support for `step_pca_sparse()`, `step_pca_sparse_bayes()` and `step_pca_truncated()` as been added. (#23)

* `orbital()` now works on `tune::last_fit()` objects. (#13)

* `orbital_predict()` has been removed and replaced with the more idiomatic `predict()` method. (#10)

# orbital 0.1.0

* Initial CRAN submission.
