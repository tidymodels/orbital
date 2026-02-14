# Floating-point precision loss in deparse/parse cycles

## The problem

When R deparses a numeric value to a string and parses it back, precision can be lost:

```r
original <- 1.65000000000000013
deparsed <- deparse1(quote(x <= 1.65000000000000013))
# "x <= 1.65"
parsed <- parse(text = deparsed)[[1]]
# x <= 1.64999999999999991
```

This tiny difference can flip comparison results at decision boundaries.

## When this matters

- Tree-based models (xgboost, lightgbm, partykit) use numeric split thresholds
- orbital converts model expressions to strings via `deparse1()` for database execution
- Test data that lands exactly on or very near split thresholds can produce different results after the deparse/parse cycle

## Symptoms

- Tests fail with mismatches at specific rows, not widespread failures
- The failing rows have predictor values very close to tree split points
- Direct evaluation of the original expression gives different results than evaluating the deparsed/parsed version

## Solutions

1. **Increase test data offsets**: If using offsets to avoid exact split values, use larger values (e.g., `0.07` or `0.1` instead of `0.05`)

2. **Debug approach**: Compare numeric values at full precision to find the problematic threshold:
   ```r
   sprintf("%.20f", original_value)
   sprintf("%.20f", parsed_value)
   ```

3. **Check which branch matches**: For case_when expressions, evaluate each condition separately on the failing row to see which branch is being selected differently

## Example debugging session

```r
# Find the precision difference
original_threshold <- expr[[3]][[2]][[3]]
parsed_threshold <- parsed[[3]][[2]][[3]]
sprintf("%.20f", original_threshold)  # 1.65000000000000013323
sprintf("%.20f", parsed_threshold)    # 1.64999999999999991118

# Check how it affects comparison
test_value <- 1.65000000000000013323
test_value <= original_threshold  # TRUE
test_value <= parsed_threshold    # FALSE
```
