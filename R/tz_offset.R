
#'
#' @title tz_offset
#' @description find the offset from UTC applied to a POSIXct object
#' @details find the offset from UTC applied to a POSIXct object
#'
#' @param x POSIXct value
#'
#' @export
#'

tz_offset <- function( x ) {

    if( !"POSIXct" %in% class( x ) ) {
        "Input must be a POSIXct class object"
    }

    shifted <- data.table::copy( x[1] )
    data.table::setattr( shifted, "tzone", "UTC" )

    unshifted <- as.character( x[1] )
    unshifted <- fasttime::fastPOSIXct( unshifted, tz = "UTC" )

    as.numeric( unshifted ) - as.numeric( shifted )

}
