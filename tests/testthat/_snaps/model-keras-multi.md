# input_names is required

    Code
      orbital(x)
    Condition
      Error in `orbital()`:
      ! `input_names` is required for bare keras3 functional models.
      i A functional model's input is an anonymous fixed-width vector with no per-feature names stored anywhere in its config, so orbital cannot infer the model's input feature names the way it can for most other model types.

# output_layer is not supported

    Code
      orbital(x, input_names = c("x1", "x2", "x3"), output_layer = 1)
    Condition
      Error in `orbital()`:
      ! `output_layer` is not supported for multi-output networks.

# a single-output functional model is rejected

    Code
      orbital(x, input_names = c("x1", "x2", "x3"))
    Condition
      Error in `orbital()`:
      ! `x` has a single output; multi-output support only applies to functional models with two or more outputs.

# multiple inputs are rejected

    Code
      orbital(x, input_names = c("x1", "x2", "x3"))
    Condition
      Error in `orbital()`:
      ! Only functional models with a single input are supported, not 2.

# mode/type/lvl must be named lists matching head names

    Code
      orbital(x, input_names = c("x1", "x2", "x3"), mode = "regression")
    Condition
      Error in `orbital()`:
      ! `mode` must be a list named by head for a multi-output network, not a string.

---

    Code
      orbital(x, input_names = c("x1", "x2", "x3"), mode = list(price = "regression",
        not_a_head = "classification"))
    Condition
      Error in `orbital()`:
      ! `mode` has names not matching any head: "not_a_head".
      i This network's heads are "price" and "category".

