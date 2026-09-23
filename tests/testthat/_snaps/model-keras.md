# input_names is required

    Code
      orbital(model)
    Condition
      Error in `orbital()`:
      ! `input_names` is required for bare keras3 <Sequential> models.
      i A <Sequential> model's input is an anonymous fixed-width vector with no per-feature names stored anywhere in its config, so orbital cannot infer the model's input feature names the way it can for most other model types.

# unsupported layers error

    Code
      orbital(model, input_names = c("x1", "x2"))
    Condition
      Error in `orbital()`:
      ! Layer <keras.src.layers.reshaping.flatten.Flatten> is not supported.
      i Supported layers are <Dense>, <Dropout>, <Activation>, <BatchNormalization>, and <LayerNormalization>.

# unsupported activations error

    Code
      orbital(model, input_names = c("x1", "x2"))
    Condition
      Error in `orbital()`:
      ! Activation "exponential" is not supported.
      i Supported activations are: "relu", "sigmoid", "tanh", "linear", "softmax", "gelu", "leaky_relu", and "elu".

# input_names length is validated against the first layer

    Code
      orbital(model, input_names = c("x1", "x2"))
    Condition
      Error in `orbital()`:
      ! `input_names` has length 2, but the first layer expects 3 inputs.

# output_layer is validated against the number of hidden layers

    Code
      orbital(model, input_names = c("x1", "x2"), mode = "regression", output_layer = 2L)
    Condition
      Error in `orbital()`:
      ! `output_layer` must be a single integer between 1 and 1, not 2.

# normalization layer must come before the activation

    Code
      orbital(model, input_names = c("x1", "x2"))
    Condition
      Error in `orbital()`:
      ! <keras.src.layers.normalization.batch_normalization.BatchNormalization> must come before the activation in each <Dense> block.
      i Got an activation already applied to this layer before <keras.src.layers.normalization.batch_normalization.BatchNormalization>.

# a Dense layer can only have one normalization layer

    Code
      orbital(model, input_names = c("x1", "x2"))
    Condition
      Error in `orbital()`:
      ! A <Dense> layer can only be followed by one normalization layer, but this one has both <keras.src.layers.normalization.batch_normalization.BatchNormalization> and <keras.src.layers.normalization.layer_normalization.LayerNormalization>.

