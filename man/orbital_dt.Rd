% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dt.R
\name{orbital_dt}
\alias{orbital_dt}
\title{Convert to data.table code}
\usage{
orbital_dt(x)
}
\arguments{
\item{x}{A orbital object.}
}
\value{
data.table code.
}
\description{
Convert to data.table code
}
\examples{
\dontshow{if (rlang::is_installed(c("dbplyr", "dtplyr", "recipes", "tidypredict", "workflows"))) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}

library(workflows)
library(recipes)
library(parsnip)

rec_spec <- recipe(mpg ~ ., data = mtcars) \%>\%
  step_normalize(all_numeric_predictors())

lm_spec <- linear_reg()

wf_spec <- workflow(rec_spec, lm_spec)

wf_fit <- fit(wf_spec, mtcars)

orbital_obj <- orbital(wf_fit)

orbital_dt(orbital_obj)
\dontshow{\}) # examplesIf}
}