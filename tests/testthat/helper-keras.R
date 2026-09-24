skip_if_no_keras <- function() {
  skip_if_not_installed("keras3")
  # The R package can be installed without a working TensorFlow/Python
  # backend (`keras3::install_keras()` never run); every call then errors
  # instead of the tests exercising anything.
  ok <- tryCatch(
    {
      keras3::keras_model_sequential(input_shape = 1)
      TRUE
    },
    error = function(cnd) FALSE
  )
  if (!ok) {
    skip("keras3's Python/TensorFlow backend is not available")
  }
}

keras_seq_model <- function(input_shape, ...) {
  keras3::set_random_seed(1)
  model <- keras3::keras_model_sequential(input_shape = input_shape)
  for (layer in list(...)) {
    model <- layer(model)
  }
  model
}

keras_predict <- function(model, data) {
  as.matrix(model$predict(as.matrix(data), verbose = 0))
}
