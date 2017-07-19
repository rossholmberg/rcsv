
#'
#' @title as_IDate
#' @description convert character time values to IDate format
#' @details takes a character vector of dates, and converts to IDate class vector
#'
#' @param x character vector of date values, formatted as YYYY-mm-dd. the hyphens can be anything
#'
#' @importFrom data.table as.IDate
#' @importFrom fasttime fastPOSIXct
#'
#' @export

as_IDate <- function(x) {
    data.table::as.IDate( fasttime::fastPOSIXct( x, tz = "UTC" ) )
}
