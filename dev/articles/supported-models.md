# Supported Models and recipes steps

The supported methods currently all come from
[tidypredict](https://tidypredict.tidymodels.org/) right now.

## Supported models

This table doesn’t exhaustively list fully unsupported models. Please
file [an issue](https://github.com/tidymodels/orbital/issues) to add
model to table.

[TABLE]

### Why some models support one classification type but not the other

The two classification columns are separate because not every model
produces both, and orbital refuses a type rather than inventing it.

**Class without probability.** Some models predict a label directly and
never compute a probability at all.
[`bag_tree()`](https://parsnip.tidymodels.org/reference/bag_tree.html)
and
[`boost_tree()`](https://parsnip.tidymodels.org/reference/boost_tree.html)
with the `"C5.0"` engine,
[`C5_rules()`](https://parsnip.tidymodels.org/reference/C5_rules.html),
and
[`bag_tree()`](https://parsnip.tidymodels.org/reference/bag_tree.html)
with `"rpart"` all reach their answer by voting across an ensemble; the
vote yields a winner, not a distribution.
[`svm_linear()`](https://parsnip.tidymodels.org/reference/svm_linear.html)
with `"LiblineaR"` produces a *decision value*, the signed distance from
the separating hyperplane. Its sign gives the class, but its magnitude
is uncalibrated: it is not a probability and does not become one by
being passed through a logistic. Doing that would attach a confidence
the model never estimated, so `type = "prob"` is refused for all of
these.

**Probability without class.**
[`pls()`](https://parsnip.tidymodels.org/reference/pls.html) with
`"mixOmics"` is the reverse case. It gives per-level values, but
mixOmics assigns a class by distance to the class centroid rather than
by taking the largest of those values, so the obvious
[`which.max()`](https://rdrr.io/r/base/which.min.html) would disagree
with the model on some rows. orbital gives the probabilities and refuses
`type = "class"`.

**Both, but the cut is not 0.5.**
[`svm_linear()`](https://parsnip.tidymodels.org/reference/svm_linear.html)
with `"kernlab"` supports both, with a wrinkle worth knowing about.
kernlab classifies by the sign of its decision function and fits its
probabilities separately, using Platt scaling. The two rules do not
cross at 0.5, so orbital emits kernlab’s own threshold as a literal in
the expression. If you compare orbital’s `.pred_class` against
thresholding its `.pred_*` columns at 0.5 yourself, expect disagreement
on rows near the boundary; orbital matches the model, and 0.5 does not.

The general rule: where a model’s own prediction rule and the naive rule
disagree, orbital follows the model.

## Recipes steps

The following 52 recipes steps are supported

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
- [`step_YeoJohnson()`](https://recipes.tidymodels.org/reference/step_YeoJohnson.html)
- [`step_zv()`](https://recipes.tidymodels.org/reference/step_zv.html)

## tailor adjustments

The following 4 tailor methods are supported

- [`tailor::adjust_equivocal_zone()`](https://tailor.tidymodels.org/reference/adjust_equivocal_zone.html)
- [`tailor::adjust_numeric_range()`](https://tailor.tidymodels.org/reference/adjust_numeric_range.html)
- [`tailor::adjust_predictions_custom()`](https://tailor.tidymodels.org/reference/adjust_predictions_custom.html)
- [`tailor::adjust_probability_threshold()`](https://tailor.tidymodels.org/reference/adjust_probability_threshold.html)
