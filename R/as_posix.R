
#'
#' @title as_posix
#' @description convert character values to POSIXct, applying timezone
#' @details timezone is applied without shifting time values
#'
#' @param x character vector of date-time values
#' @param tz timezone value to be applied
#'
#' @export

as_posix <- function( x, tz = "Australia/Melbourne" ) {

    test.value <- x[1]

    # create two values, one shifted, one not shifted
    unshifted <- fasttime::fastPOSIXct( test.value, tz = "UTC" )

    shifted <- fasttime::fastPOSIXct( copy( test.value ), tz = "UTC" )
    data.table::setattr( shifted, "tzone", tz )
    shifted <- as.character( shifted )
    shifted <- fasttime::fastPOSIXct( shifted, tz = "UTC" )

    # see what the offset is
    offset <- as.numeric( shifted ) - as.numeric( unshifted )

    # compensate for the offset
    fasttime::fastPOSIXct( x, tz = tz ) - offset

}
