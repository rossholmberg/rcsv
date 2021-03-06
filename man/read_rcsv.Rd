% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read_rcsv.R
\name{read_rcsv}
\alias{read_rcsv}
\title{read_rcsv}
\usage{
read_rcsv(file, subset = NULL, echo.notes = TRUE)
}
\arguments{
\item{file}{file path to which the rscv will be written}

\item{subset}{integer vector of rows to read}

\item{echo.notes}{print notes to the console on import?}
}
\description{
an extension of the csv file format
}
\details{
read an rcsv file, an extension of csv, with column format details
stored in a header for more consistent reading into R
}
