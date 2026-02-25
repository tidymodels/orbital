# Supported Models and recipes steps

The supported methods currently all come from
[tidypredict](https://tidypredict.tidymodels.org/) right now.

## Supported models

This table doesn’t exhaustively list fully unsupported models. Please
file [an issue](https://github.com/tidymodels/orbital/issues) to add
model to table.

[TABLE]

## Recipes steps

The following 51 recipes steps are supported

- `step_adasyn()`
- [`step_bin2factor()`](https://recipes.tidymodels.org/reference/step_bin2factor.html)
- [`step_BoxCox()`](https://recipes.tidymodels.org/reference/step_BoxCox.html)
- `step_bsmote()`
- [`step_center()`](https://recipes.tidymodels.org/reference/step_center.html)
- [`step_corr()`](https://recipes.tidymodels.org/reference/step_corr.html)
- [`step_discretize()`](https://recipes.tidymodels.org/reference/step_discretize.html)
- `step_downsample()`
- [`step_dummy()`](https://recipes.tidymodels.org/reference/step_dummy.html)
- [`step_filter_missing()`](https://recipes.tidymodels.org/reference/step_filter_missing.html)
- [`step_impute_mean()`](https://recipes.tidymodels.org/reference/step_impute_mean.html)
- [`step_impute_median()`](https://recipes.tidymodels.org/reference/step_impute_median.html)
- [`step_impute_mode()`](https://recipes.tidymodels.org/reference/step_impute_mode.html)
- [`step_indicate_na()`](https://recipes.tidymodels.org/reference/step_indicate_na.html)
- [`step_intercept()`](https://recipes.tidymodels.org/reference/step_intercept.html)
- [`step_inverse()`](https://recipes.tidymodels.org/reference/step_inverse.html)
- [`step_lag()`](https://recipes.tidymodels.org/reference/step_lag.html)
- `step_lencode_bayes()`
- `step_lencode_glm()`
- `step_lencode_mixed()`
- [`step_lincomb()`](https://recipes.tidymodels.org/reference/step_lincomb.html)
- [`step_log()`](https://recipes.tidymodels.org/reference/step_log.html)
- [`step_mutate()`](https://recipes.tidymodels.org/reference/step_mutate.html)
- `step_nearmiss()`
- [`step_normalize()`](https://recipes.tidymodels.org/reference/step_normalize.html)
- [`step_novel()`](https://recipes.tidymodels.org/reference/step_novel.html)
- [`step_nzv()`](https://recipes.tidymodels.org/reference/step_nzv.html)
- [`step_other()`](https://recipes.tidymodels.org/reference/step_other.html)
- [`step_pca()`](https://recipes.tidymodels.org/reference/step_pca.html)
- `step_pca_sparse()`
- `step_pca_sparse_bayes()`
- `step_pca_truncated()`
- [`step_range()`](https://recipes.tidymodels.org/reference/step_range.html)
- [`step_ratio()`](https://recipes.tidymodels.org/reference/step_ratio.html)
- [`step_rename()`](https://recipes.tidymodels.org/reference/step_rename.html)
- [`step_rm()`](https://recipes.tidymodels.org/reference/step_rm.html)
- `step_rose()`
- [`step_scale()`](https://recipes.tidymodels.org/reference/step_scale.html)
- [`step_select()`](https://recipes.tidymodels.org/reference/step_select.html)
- `step_smote()`
- `step_smotenc()`
- [`step_spline_b()`](https://recipes.tidymodels.org/reference/step_spline_b.html)
- [`step_spline_convex()`](https://recipes.tidymodels.org/reference/step_spline_convex.html)
- [`step_spline_monotone()`](https://recipes.tidymodels.org/reference/step_spline_monotone.html)
- [`step_spline_natural()`](https://recipes.tidymodels.org/reference/step_spline_natural.html)
- [`step_spline_nonnegative()`](https://recipes.tidymodels.org/reference/step_spline_nonnegative.html)
- [`step_sqrt()`](https://recipes.tidymodels.org/reference/step_sqrt.html)
- `step_tomek()`
- [`step_unknown()`](https://recipes.tidymodels.org/reference/step_unknown.html)
- `step_upsample()`
- [`step_zv()`](https://recipes.tidymodels.org/reference/step_zv.html)

## tailor adjustments

The following 4 tailor methods are supported

- [`tailor::adjust_equivocal_zone()`](https://tailor.tidymodels.org/reference/adjust_equivocal_zone.html)
- [`tailor::adjust_numeric_range()`](https://tailor.tidymodels.org/reference/adjust_numeric_range.html)
- [`tailor::adjust_predictions_custom()`](https://tailor.tidymodels.org/reference/adjust_predictions_custom.html)
- [`tailor::adjust_probability_threshold()`](https://tailor.tidymodels.org/reference/adjust_probability_threshold.html)
