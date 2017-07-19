
#'
#' @title as_char_time
#' @description convert time values to character strings
#' @details takes a vector of times, and converts to character vector
#'
#' @param x time vector eg: integer, times, or ITime classes
#'
#' @export
#'

as_char_time <- function( x ) {
    if( class( x ) == "times" ) {
        x <- as.integer( round( x * 86400 ) )
    }
    .Call('rcsv_asCharTime', PACKAGE = 'rcsv', x)
}
