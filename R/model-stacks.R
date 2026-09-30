# A fitted stacks::model_stack blends several trained workflows (the
# "members") with a glmnet elastic-net model (`x$coefs`, itself a normal
# parsnip model_fit). `orbital(x$coefs)` already works unmodified: its
# `preproc` term labels are exactly the member prediction column names it
# expects as predictors. So this method only has to (1) build each member's
# own equations, (2) rename their outputs to the column names the blend model
# expects, and (3) splice the two sets of equations together.
#
# Renaming can't be a plain `names<-`: a member's own equations can
# cross-reference each other by name (binary classification's
# `.pred_Class2 = 1 - `.pred_Class1``, or a multiclass member's `.pred_setosa`
# referencing an intermediate `norm` column), so every backtick-quoted
# reference has to be substituted everywhere, not just the top-level names.

#' @export
orbital.model_stack <- function(
  x,
  ...,
  prefix = ".pred",
  type = NULL,
  separate_trees = FALSE
) {
  check_fitted_stack(x)

  mode <- x$mode
  check_mode(mode)
  check_type(type, mode)
  member_names <- names(x$member_fits)

  member_eqs <- character(0)
  for (nm in member_names) {
    member_wf <- x$member_fits[[nm]]

    eq <- rlang::try_fetch(
      if (mode == "regression") {
        orbital(member_wf, type = "numeric", separate_trees = separate_trees)
      } else {
        orbital(member_wf, type = "prob", separate_trees = separate_trees)
      },
      error = function(cnd) {
        cli::cli_abort(
          "Failed to build equations for stack member {.val {nm}}.",
          parent = cnd
        )
      }
    )

    member_eqs <- c(member_eqs, rename_stack_member_eqs(eq, mode, nm))
  }

  dupe_names <- unique(names(member_eqs)[duplicated(names(member_eqs))])
  if (length(dupe_names) > 0) {
    cli::cli_abort(
      "Stack members produced colliding equation names: {.val {dupe_names}}."
    )
  }

  blend_eq <- orbital(x$coefs, prefix = prefix, type = type)

  res <- c(member_eqs, unclass(blend_eq))
  attr(res, "pred_names") <- attr(blend_eq, "pred_names")
  new_orbital_class(res)
}

# Regression members contribute a single column, and it must be renamed to
# exactly `member_name` (no prefix, no suffix) since that's the raw column
# name `x$coefs`'s glmnet fit was trained on. Classification members
# contribute one column per class, each renamed to
# `<original_name>_<member_name>` (e.g. `.pred_Class2_<member_name>`), which
# is what stacks names those predictor columns.
#
# Any other equations a member produces (intermediate columns from a
# multiclass softmax, `separate_trees = TRUE` per-tree columns, etc.) aren't
# referenced by the blend model, but still get a `_<member_name>` suffix so
# they can't collide with another member's equations of the same name.
rename_stack_member_eqs <- function(eq, mode, member_name) {
  pred_names <- attr(eq, "pred_names")
  old_names <- names(eq)
  eq <- unclass(eq)

  if (mode == "regression") {
    is_pred <- old_names %in% pred_names
    new_names <- old_names
    new_names[is_pred] <- member_name
    new_names[!is_pred] <- paste0(old_names[!is_pred], "_", member_name)
  } else {
    new_names <- paste0(old_names, "_", member_name)
  }

  # Longest names first so a shorter name that happens to be a substring of a
  # longer one (e.g. "norm" inside "norm2") can't clobber part of it.
  ord <- order(nchar(old_names), decreasing = TRUE)
  for (i in ord) {
    pattern <- paste0("`", old_names[i], "`")
    replacement <- paste0("`", new_names[i], "`")
    eq <- gsub(pattern, replacement, eq, fixed = TRUE)
  }

  names(eq) <- new_names
  eq
}

check_fitted_stack <- function(x, call = rlang::caller_env()) {
  if (
    is.null(x$member_fits) ||
      length(x$member_fits) == 0 ||
      !inherits(x$coefs, "model_fit")
  ) {
    cli::cli_abort(
      c(
        "{.arg x} must be a fully fitted {.cls model_stack}.",
        i = "Run {.fn stacks::fit_members} on the blended stack first."
      ),
      call = call
    )
  }
}
