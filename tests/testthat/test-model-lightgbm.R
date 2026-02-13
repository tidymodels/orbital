test_that("boost_tree(engine = 'lightgbm'), objective = regression, works with type = numeric", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  bt_spec <- parsnip::boost_tree(
    mode = "regression",
    engine = "lightgbm",
    min_n = 1
  )

  bt_fit <- parsnip::fit(bt_spec, mpg ~ disp + vs + hp, mtcars)

  orb_obj <- orbital(bt_fit)

  # to avoid exact split values
  mtcars <- mtcars + 0.1

  preds <- predict(orb_obj, mtcars)
  exps <- predict(bt_fit, mtcars)

  expect_named(preds, ".pred")
  expect_type(preds$.pred, "double")

  exps <- as.data.frame(exps)

  rownames(preds) <- NULL
  rownames(exps) <- NULL

  expect_equal(
    preds,
    exps,
    tolerance = 0.0000001
  )
})
