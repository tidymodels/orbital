# nn_activation_expr() errors on an unsupported activation

    Code
      nn_activation_expr("x", "swish")
    Condition
      Error:
      ! Activation "swish" is not supported.
      i Supported activations are: "relu", "sigmoid", "tanh", "linear", "identity", "leaky_relu", "elu", and "gelu".

# nn_output_eqs() errors for a multi-unit regression network

    Code
      nn_output_eqs(c(a = "1", b = "2"), "identity", mode = "regression")
    Condition
      Error:
      ! A regression network must have exactly one output unit, not 2.

# nn_output_eqs() errors for a bound regression activation

    Code
      nn_output_eqs(c(out = "1"), "sigmoid", mode = "regression")
    Condition
      Error:
      ! A regression network's final activation must be "linear" or "identity", not "sigmoid".
      i Bound outputs (e.g. a trailing sigmoid) are not regression outputs orbital can infer automatically; pass an explicit `mode` if this is intentional.

# nn_output_eqs() errors on sigmoid with two or more output units

    Code
      nn_output_eqs(c(a = "1", b = "2"), "sigmoid", mode = "classification", type = "class",
      lvl = c("a", "b"))
    Condition
      Error:
      ! Activation "sigmoid" is not supported as a final-layer activation for a 2-unit classification output.
      i Supported final-layer activations for two or more output units are "linear"/"identity" (raw per-class scores) and "softmax" (routed the same way, since softmax cannot be computed per neuron and the stored values are always the pre-softmax logits).

# nn_output_eqs() errors on softmax with a single output unit

    Code
      nn_output_eqs(c(out = "1"), "softmax", mode = "classification", type = "class",
      lvl = c("yes", "no"))
    Condition
      Error:
      ! A single-output-unit classification network's final activation must be "sigmoid", "linear", or "identity", not "softmax".
      i A single output unit is always treated as a binary classification logit and passed through a sigmoid, whether or not the source model applied one explicitly.

# nn_output_eqs() errors on an unsupported final activation (single output unit)

    Code
      nn_output_eqs(c(out = "1"), "tanh", mode = "classification")
    Condition
      Error:
      ! A single-output-unit classification network's final activation must be "sigmoid", "linear", or "identity", not "tanh".
      i A single output unit is always treated as a binary classification logit and passed through a sigmoid, whether or not the source model applied one explicitly.

# nn_output_eqs() errors on an unsupported final activation (two or more output units)

    Code
      nn_output_eqs(c(a = "1", b = "2"), "tanh", mode = "classification")
    Condition
      Error:
      ! Activation "tanh" is not supported as a final-layer activation for a 2-unit classification output.
      i Supported final-layer activations for two or more output units are "linear"/"identity" (raw per-class scores) and "softmax" (routed the same way, since softmax cannot be computed per neuron and the stored values are always the pre-softmax logits).

