# input_names is required

    Code
      orbital(model)
    Condition
      Error in `orbital()`:
      ! `input_names` is required for bare <nn_sequential> models.
      i Torch tensors are positional and carry no column names, so orbital cannot infer the model's input feature names the way it can for most other model types.

# unsupported modules error

    Code
      orbital(model, input_names = c("x1", "x2"))
    Condition
      Error in `orbital()`:
      ! Module <nn_softmin> is not supported.
      i Supported modules are <nn_linear>, <nn_dropout>, the activation modules <nn_relu/nn_sigmoid/nn_tanh/nn_identity/nn_gelu/nn_leaky_relu/nn_elu/nn_softmax>, and the normalization modules <nn_batch_norm1d/nn_layer_norm>.

# input_names length is validated against the first layer

    Code
      orbital(model, input_names = c("x1", "x2"))
    Condition
      Error in `orbital()`:
      ! `input_names` has length 2, but the first layer expects 3 inputs.

# lvl length is validated against the network's output width

    Code
      orbital(bin_model, input_names = c("x1", "x2"), mode = "classification", lvl = "only_one")
    Condition
      Error in `orbital()`:
      ! `lvl` must have length 2, not 1.
      i A single output unit is always treated as binary classification, which requires 2 levels.

---

    Code
      orbital(multi_model, input_names = c("x1", "x2"), mode = "classification", lvl = c(
        "a", "b"))
    Condition
      Error in `orbital()`:
      ! `lvl` must have length 3, not 2.
      i The network has 3 output units.

# orbital.nn_sequential validates type against mode

    Code
      orbital(model, input_names = c("x1", "x2"), mode = "classification", type = "numeric")
    Condition
      Error in `orbital()`:
      ! `type` can only be "class" or "prob" for model with mode "classification", not "numeric".

# nn_softmax is only supported as the final layer's activation

    Code
      orbital(model, input_names = c("x1", "x2"))
    Condition
      Error in `orbital()`:
      ! <nn_softmax> is only supported as the final layer's activation.
      i Softmax cannot be computed per neuron, so it can't be used on a hidden layer.

# nn_softmax over a non-class dimension errors

    Code
      orbital(model, input_names = c("x1", "x2"))
    Condition
      Error in `orbital()`:
      ! <nn_softmax> is only supported when normalizing over the last dimension (the per-example class scores).
      i Got `dim = 1`; only `dim = 2` or `dim = -1` are supported.

# normalization module must come before the activation

    Code
      orbital(model, input_names = c("x1", "x2"))
    Condition
      Error in `orbital()`:
      ! <nn_batch_norm1d> must come before the activation module in each <nn_linear> block.
      i Got an activation module already applied to this layer before <nn_batch_norm1d>.

# a linear layer can only have one normalization module

    Code
      orbital(model, input_names = c("x1", "x2"))
    Condition
      Error in `orbital()`:
      ! A <nn_linear> layer can only be followed by one normalization module, but this one has both <nn_batch_norm1d> and <nn_layer_norm>.

# nn_batch_norm1d with track_running_stats = FALSE errors

    Code
      orbital(model, input_names = c("x1", "x2"))
    Condition
      Error in `orbital()`:
      ! <nn_batch_norm1d> with `track_running_stats = FALSE` is not supported.
      i Without stored running statistics, its evaluation-time output depends on each prediction batch's own statistics, which orbital cannot reproduce as a fixed per-row expression.

# nn_layer_norm normalizing over a mismatched width errors

    Code
      orbital(model, input_names = c("x1", "x2"))
    Condition
      Error in `orbital()`:
      ! <nn_layer_norm> is only supported when normalizing over exactly the preceding layer's 4 output units.
      i Got `normalized_shape = 2`.

# output_layer is validated against the number of hidden layers

    Code
      orbital(model, input_names = c("x1", "x2"), mode = "regression", output_layer = 2L)
    Condition
      Error in `orbital()`:
      ! `output_layer` must be a single integer between 1 and 1, not 2.

