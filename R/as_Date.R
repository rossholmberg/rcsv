
#'
#' @title as_Date
#' @description convert character time values to Date format
#' @details takes a character vector of dates, and converts to Date class vector
#'
#' @param x character vector of date values, formatted as YYYY-mm-dd. the hyphens can be anything
#'
#' @importFrom fasttime fastPOSIXct
#'
#' @export

as_Date <- function(x) {
    as.Date( fasttime::fastPOSIXct( x, tz = "UTC" ) )
}
