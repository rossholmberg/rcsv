
#'
#' @title as_ITime
#' @description convert character time values to ITime format
#' @details takes a character vector of times, and converts to ITime class vector
#'
#' @param x character vector of time values
#'
#' @export

as_ITime <- function(x) {
    t <- .Call('rcsv_toTimeSec', PACKAGE = 'rcsv', x)
    setattr( t, "class", "ITime" )
    t
}
