skip_if_no_brulee <- function() {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("brulee")
  skip_if_not_installed("torch")
  # See `tests/testthat/test-model-torch.R`: the R package can be installed
  # without LibTorch itself.
  if (!torch::torch_is_installed()) {
    skip("libtorch is not installed")
  }
}

# mtcars's predictors span wildly different scales (disp up to ~470, wt under
# 6), which combined with a few unscaled ReLU layers is enough to overflow
# LBFGS (brulee's default optimizer) during training; scaling avoids that
# without changing anything the extraction code is exercising.
scaled_mtcars <- within(mtcars, {
  disp <- scale(disp)[, 1]
  hp <- scale(hp)[, 1]
  wt <- scale(wt)[, 1]
})

brulee_mlp_fit <- function(mode, formula, data, hidden_units = c(6, 5)) {
  set.seed(1)
  torch::torch_manual_seed(1)
  parsnip::fit(
    parsnip::set_mode(
      parsnip::set_engine(
        parsnip::mlp(
          epochs = 15,
          hidden_units = hidden_units,
          activation = "relu",
          learn_rate = 0.01
        ),
        "brulee"
      ),
      mode
    ),
    formula,
    data
  )
}
