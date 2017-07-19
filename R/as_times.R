
#'
#' @title as_times
#' @description convert character time values to times format
#' @details takes a character vector of times, and converts to times class vector
#'
#' @param x character vector of time values
#'
#' @importFrom chron times
#'
#' @export

as_times <- function(x) {
    chron::times( .Call('rcsv_toTimeDay', PACKAGE = 'rcsv', x) )
}
