skip_if_no_torch <- function() {
  skip_if_not_installed("torch")
  # The R package can be installed without LibTorch itself (`install_torch()`
  # never run), which is the state most CI runners are in; every torch call
  # then errors with "Lantern is not loaded" instead of the tests exercising
  # anything.
  if (!torch::torch_is_installed()) {
    skip("libtorch is not installed")
  }
}

torch_seq_model <- function(...) {
  torch::torch_manual_seed(1)
  torch::nn_sequential(...)
}

torch_predict <- function(model, data) {
  x <- torch::torch_tensor(as.matrix(data))
  as.matrix(model(x))
}
