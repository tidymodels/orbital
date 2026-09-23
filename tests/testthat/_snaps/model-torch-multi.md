# input_names is required

    Code
      orbital(x)
    Condition
      Error in `orbital()`:
      ! `input_names` is required for multi-output networks.
      i Torch tensors are positional and carry no column names, so orbital cannot infer the model's input feature names the way it can for most other model types.

# x must have exactly trunk and heads elements

    Code
      orbital(list(a = 1, b = 2), input_names = "x1")
    Condition
      Error in `orbital()`:
      ! A multi-output network must be a list with exactly two named elements, trunk and heads.
      i Got names "a" and "b".

# trunk must be an nn_sequential

    Code
      orbital(x, input_names = c("x1", "x2", "x3"))
    Condition
      Error in `orbital()`:
      ! trunk must be a <nn_sequential>, not a string.

# heads must be a non-empty named list of nn_sequential

    Code
      orbital(x, input_names = c("x1", "x2", "x3"))
    Condition
      Error in `orbital()`:
      ! heads must be a non-empty list with unique names.

---

    Code
      orbital(x, input_names = c("x1", "x2", "x3"))
    Condition
      Error in `orbital()`:
      ! Every element of heads must be a <nn_sequential>, but "price" is not.

# output_layer is not supported

    Code
      orbital(x, input_names = c("x1", "x2", "x3"), output_layer = 1)
    Condition
      Error in `orbital()`:
      ! `output_layer` is not supported for multi-output networks.

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

