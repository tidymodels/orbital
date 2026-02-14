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

test_that("boost_tree(engine = 'lightgbm'), objective = binary, works with type = class", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  mtcars$vs <- factor(mtcars$vs)

  bt_spec <- parsnip::boost_tree(
    mode = "classification",
    engine = "lightgbm",
    min_n = 1
  )

  bt_fit <- parsnip::fit(bt_spec, vs ~ disp + mpg + hp, mtcars)

  orb_obj <- orbital(bt_fit, type = "class")

  # to avoid exact split values
  mtcars[, -8] <- mtcars[, -8] + 0.1

  preds <- predict(orb_obj, mtcars)
  exps <- predict(bt_fit, mtcars)

  expect_named(preds, ".pred_class")
  expect_type(preds$.pred_class, "character")

  expect_identical(
    preds$.pred_class,
    as.character(exps$.pred_class)
  )
})

test_that("boost_tree(engine = 'lightgbm'), objective = binary, works with type = prob", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  mtcars$vs <- factor(mtcars$vs)

  bt_spec <- parsnip::boost_tree(
    mode = "classification",
    engine = "lightgbm",
    min_n = 1
  )

  bt_fit <- parsnip::fit(bt_spec, vs ~ disp + mpg + hp, mtcars)

  orb_obj <- orbital(bt_fit, type = "prob")

  # to avoid exact split values
  mtcars[, -8] <- mtcars[, -8] + 0.1

  preds <- predict(orb_obj, mtcars)
  exps <- predict(bt_fit, mtcars, type = "prob")

  expect_named(preds, c(".pred_0", ".pred_1"))
  expect_type(preds$.pred_0, "double")
  expect_type(preds$.pred_1, "double")

  exps <- as.data.frame(exps)

  rownames(preds) <- NULL
  rownames(exps) <- NULL

  expect_equal(
    preds,
    exps,
    tolerance = 0.0000001
  )
})

test_that("boost_tree(engine = 'lightgbm'), objective = binary, works with type = c(class, prob)", {
  skip_if_not_installed("parsnip")
  skip_if_not_installed("bonsai")
  skip_if_not_installed("tidypredict")
  skip_if_not_installed("lightgbm")

  mtcars$vs <- factor(mtcars$vs)

  bt_spec <- parsnip::boost_tree(
    mode = "classification",
    engine = "lightgbm",
    min_n = 1
  )

  bt_fit <- parsnip::fit(bt_spec, vs ~ disp + mpg + hp, mtcars)

  orb_obj <- orbital(bt_fit, type = c("class", "prob"))

  # to avoid exact split values
  mtcars[, -8] <- mtcars[, -8] + 0.1

  preds <- predict(orb_obj, mtcars)
  exps <- dplyr::bind_cols(
    predict(bt_fit, mtcars, type = "class"),
    predict(bt_fit, mtcars, type = "prob")
  )

  expect_named(preds, c(".pred_class", ".pred_0", ".pred_1"))
  expect_type(preds$.pred_class, "character")
  expect_type(preds$.pred_0, "double")
  expect_type(preds$.pred_1, "double")

  exps <- as.data.frame(exps)
  exps$.pred_class <- as.character(exps$.pred_class)

  rownames(preds) <- NULL
  rownames(exps) <- NULL

  expect_equal(
    preds,
    exps,
    tolerance = 0.0000001
  )
})
