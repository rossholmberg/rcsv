% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/as_posix.R
\name{as_posix}
\alias{as_posix}
\title{as_posix}
\usage{
as_posix(x, tz = "Australia/Melbourne")
}
\arguments{
\item{x}{character vector of date-time values}

\item{tz}{timezone value to be applied}
}
\description{
convert character values to POSIXct, applying timezone
}
\details{
timezone is applied without shifting time values
}
