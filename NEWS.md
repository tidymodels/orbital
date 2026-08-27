# orbital (development version)

## New models

* `bag_tree()` with the `"rpart"` and `"C5.0"` engines is now supported for `type = "class"`. These models vote over their ensemble and expose no probability, so `type = "prob"` is refused. (#161)

* `bart()` with the `"dbarts"` engine is now supported for regression. Classification is refused, since it uses a probit link that cannot be translated. (#162)

* `boost_tree()` with the `"C5.0"` engine is now supported for `type = "class"`, including multi-trial boosting. (#161)

* `boost_tree()` with the `"h2o_gbm"` engine, and `rule_fit()` with the `"h2o"` engine, are now supported for regression and classification. A running H2O cluster is needed to build the orbital object, but not to use one afterwards. (#166)

* `C5_rules()` with the `"C5.0"` engine is now supported for `type = "class"`. (#161)

* `discrim_linear()` and `discrim_quad()` with the `"MASS"` engine are now supported for `type = "class"` and `type = "prob"`. (#160)

* `discrim_linear()` with the `"mda"`, `"sda"`, and `"sparsediscrim"` engines is now supported for `type = "class"` and `type = "prob"`. (#163)

* `linear_reg()` with the `"glm"` engine is now supported. (#160)

* `logistic_reg()` with the `"LiblineaR"` engine is now supported for `type = "class"` and `type = "prob"`. (#164)

* `mlp()` with the `"nnet"` engine is now supported for regression and classification. (#160)

* `multinom_reg()` with the `"nnet"` engine is now supported for `type = "class"` and `type = "prob"`. (#160)

* `naive_Bayes()` with the `"klaR"` and `"naivebayes"` engines is now supported for `type = "class"` and `type = "prob"`. Both engines default to `usekernel = TRUE`, which fits a kernel density per predictor and has no closed form; refit with `usekernel = FALSE` to translate one. (#163)

* `null_model()` is now supported for regression and classification. (#160)

* `pls()` with the `"mixOmics"` engine is now supported for regression and for `type = "prob"`. `type = "class"` is refused, since mixOmics assigns a class by distance to the class centroid rather than by the largest per-level value. (#163)

* `rand_forest()` with the `"partykit"` engine is now supported for regression. (#161)

* `rule_fit()` with the `"xrf"` engine is now supported for regression and for binary classification. Multiclass outcomes are refused, since xrf only fits Gaussian and binomial models. (#164)

* `svm_linear()` with the `"kernlab"` engine is now supported for regression and classification. (#164)

* `svm_linear()` with the `"LiblineaR"` engine is now supported for regression, in addition to the `type = "class"` support added in #159. (#164)

## Improvements

* `orbital()` now supports classification models that reach the tidypredict fallback, rather than refusing them. This covers multiclass probability models such as `MASS::lda()`, models returning an uncalibrated decision value such as `LiblineaR` SVMs, and models predicting a class label directly such as `C50::C5.0()`. (#159)

* `orbital()` refuses `type = "prob"` for models that have no probability to give, rather than fabricating one. A decision value is uncalibrated, so putting it through a logistic would invent a calibration the model does not have. (#159)

## Bug fixes

* `estimate_orbital_size()` now errors for a workflow whose model it has no estimate for, rather than counting that model as zero characters and returning the recipe's size as the whole workflow's. The model is usually the bulk of the expression, so the number it returned could be off by orders of magnitude while looking ordinary, and it did not move as the model's hyperparameters changed. (#167)

* `orbital()` now errors for a bare model fit, which was never documented input, rather than returning something that looked like a result. A regression fit handed in directly took the classification path whatever the model was, so `orbital(rpart::rpart(mpg ~ ., mtcars))` came back as a character vector named `orbital_tmp_class_name` with no error and no warning. Fit the model with `parsnip::fit()`, or use a workflow, as the documentation has always described. (#113)

* `orbital()` now uses the model's own class order for binary probabilities, rather than assuming it matches the order of the outcome's factor levels. Every engine but h2o orders them the same way, so only h2o models were affected, and only when the outcome's levels were not in sorted order; for those both probability columns were swapped and the class inverted. (#166)

* `orbital()` now returns the correct classes for `svm_linear()` models with the `"LiblineaR"` engine. The sign of the decision value was read as meaning the second outcome level, but LiblineaR orients it by its own class order, which need not match the order of the outcome's factor levels. When the two disagreed every class was inverted. (#164)

* `orbital()` now returns the correct classes for `svm_linear()` models with the `"kernlab"` engine. kernlab classifies by the sign of its decision function and calibrates its probabilities separately, so cutting those probabilities at 0.5 disagreed with the model for rows near the boundary. (#164)

* Binary `earth()` classification models now generate `1 / (1 + exp(-x))` rather than the equivalent `1 - 1 / (1 + exp(x))`. Predictions are unchanged. (#158)

* `orbital(separate_trees = TRUE)` now returns `NA` for rows with a missing predictor, matching what `separate_trees = FALSE` has always returned. The individual tree expressions fall through to their default branch when a split variable is `NA`, so such rows previously received a confident-looking prediction computed from no usable data. (#158)

* `orbital(separate_trees = TRUE)` now applies CatBoost's scale and bias to binary classification models. The regression path applied them and the binary path did not, so the two disagreed with `separate_trees = FALSE` whenever a model carried a non-default scale or bias. (#158)

* `orbital()` no longer falls back to tidypredict when one of its own model methods errors. An error in a native method was previously caught and silently replaced with a tidypredict result, so a bug could still produce an answer. Whether a native method exists is now checked directly, and errors from it propagate. (#156)

* `orbital()` now errors for classification models that reach the tidypredict fallback, instead of returning prediction columns named after tidypredict's internals. (#156)

* `print()` no longer corrupts numbers when rounding them for display. Numbers such as `6.75044994983228` and `-0.0901719835820594` were printed as `6.750.5` and `-017198`. Only the printed output was affected; the expressions themselves were always correct. (#155)

# orbital 0.5.1

## Improvements

* `estimate_orbital_size()` is a new function that quickly estimates the character count of the orbital expression for a model without generating it. (#144)

## Bug fixes

* `step_dummy()` and `step_indicate_na()` now generate SQL compatible with Snowflake and other databases that don't support casting booleans directly to numeric types. (#145)

# orbital 0.5.0

## New models

* `orbital()` now works with `boost_tree(engine = "catboost")` models for numeric, class, and probability predictions. (#90)

* `orbital()` now works with `boost_tree(engine = "lightgbm")` models for numeric, class, and probability predictions. (#89)

* `orbital()` now works with `decision_tree(engine = "rpart")` models for numeric, class, and probability predictions. (#128)

* `orbital()` now works with `mars(engine = "earth")` models for class and probability predictions. (#127)

* `orbital()` now works with `multinom_reg(engine = "glmnet")` models for class and probability predictions. (#127)

* `orbital()` now works with `rand_forest(engine = "randomForest")` models for class and probability predictions. (#127)

* `orbital()` now works with `rand_forest(engine = "ranger")` models for class and probability predictions. (#127)

## Improvements

* `orbital()` gains a `separate_trees` argument for tree ensemble models (xgboost, lightgbm, catboost, ranger, randomForest). When `TRUE`, each tree is emitted as a separate intermediate column before being summed, which can enable parallel evaluation in columnar databases like DuckDB, Snowflake, and BigQuery. For models with many trees, the final summation is automatically batched in groups of 50 to avoid expression depth limits in databases. See the "Separate trees" vignette for details. (#105)

* Added support for `step_spline_b()`, `step_spline_convex()`, `step_spline_monotone()`, `step_spline_natural()`, and `step_spline_nonnegative()` from the recipes package. (#99)

* `step_YeoJohnson()` is now supported. (#96)

* Binary classification probability predictions now generate cleaner code by having the second probability reference the first (e.g., `.pred_1 = 1 - .pred_0`) instead of duplicating the full expression. (#100)

* New "Database deployment" vignette shows how to deploy predictions to a database as tables or views. (#74)

* New "SQL size" vignette documents how model type and hyperparameters affect generated SQL size, and shows how to jointly tune for predictive performance and SQL complexity.

## Bug fixes

* All numeric values embedded in SQL expressions now use full IEEE 754 double precision (17 significant digits) to ensure exact round-trip accuracy between R and database predictions. This prevents subtle numerical drift in regularized model coefficients, normalized features, and tree split values. (#138)

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
