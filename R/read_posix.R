


read_posix <- function( times, tz ) {

    # create two values, one shifted, one not shifted
    unshifted <- fasttime::fastPOSIXct( times[1], tz = "UTC" )
    shifted <- fasttime::fastPOSIXct( as.character( unshifted ), tz = "UTC" )

    # see what the offset is
    offset <- as.numeric( unshifted ) - as.numeric( shifted )

    # compensate for the offset
    fasttime::fastPOSIXct( times, tz = tz ) + offset

}
