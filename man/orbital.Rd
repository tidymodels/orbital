% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/orbital.R
\name{orbital}
\alias{orbital}
\title{Turn tidymodels objects into orbital objects}
\usage{
orbital(x, ..., prefix = ".pred", type = NULL)
}
\arguments{
\item{x}{A fitted workflow, parsnip, or recipes object.}

\item{...}{Not currently used.}

\item{prefix}{A single string, specifies the prediction naming scheme.
If \code{x} produces a prediction, tidymodels standards dictate that the
predictions will start with \code{.pred}. This is not a valid name for
some data bases.}

\item{type}{A vector of strings, specifies the prediction type. Regression
models allow for \code{"numeric"} and classification models allow for \code{"class"}
and \code{"prob"}. Multiple values are allowed to produce hard and soft
predictions for classification models. Defaults to \code{NULL} which defaults to
\code{"numeric"} for regression models and \code{"class"} for classification models.}
}
\value{
An \link{orbital} object.
}
\description{
Fitted workflows, parsnip objects, and recipes objects can be turned into an
orbital object that contain all the information needed to perform
predictions.
}
\details{
An orbital object contains all the information that is needed to perform
predictions. This makes the objects substantially smaller than the original
objects. The main downside with this object is that all the input checking
has been removed, and it is thus up to the user to make sure the data is
correct.

The printing of orbital objects reduce the number of significant digits for
easy viewing, the can be changes by using the \code{digits} argument of \code{print()}
like so \code{print(orbital_object, digits = 10)}. The printing likewise truncates
each equation to fit on one line. This can be turned off using the \code{truncate}
argument like so \code{print(orbital_object, truncate = FALSE)}.

Full list of supported models and recipes steps can be found here:
\code{vignette("supported-models")}.

These objects will not be useful by themselves. They can be used to
\link[=predict.orbital_class]{predict()} with, or to generate code using functions
such as \code{\link[=orbital_sql]{orbital_sql()}} or \code{\link[=orbital_dt]{orbital_dt()}}.
}
\examples{
\dontshow{if (rlang::is_installed(c("recipes", "tidypredict", "workflows"))) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
library(workflows)
library(recipes)
library(parsnip)

rec_spec <- recipe(mpg ~ ., data = mtcars) |>
  step_normalize(all_numeric_predictors())

lm_spec <- linear_reg()

wf_spec <- workflow(rec_spec, lm_spec)

wf_fit <- fit(wf_spec, mtcars)

orbital(wf_fit)

# Also works on parsnip object by itself
fit(lm_spec, mpg ~ disp, data = mtcars) |>
  orbital()

# And prepped recipes
prep(rec_spec) |>
  orbital()
\dontshow{\}) # examplesIf}
}
