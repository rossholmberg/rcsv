
#'
#' @title names_rcsv
#' @description extract column names from an rcsv file
#' @details  extract column names from an rcsv file without loading
#' the entire file into memory
#'
#' @param file file path from which the rscv will be read
#'
#' @export


names_rcsv <- function( file ) {
    # open a connection to the file
    con <- file( file, "r" )

    # read in a single line, this will contain the number of header lines
    head.line <- readLines( con = con, n = 1 )

    # check for the tag verifying this file as an rcsv file
    if( !grepl( "rcsvHeader", head.line ) ) {
        stop( "This is not an rcsv file, consider using a different file reader." )
    }

    head.lines <- as.integer( gsub( ".*headlines:|}.*", "", head.line ) )

    # read in the header, and close the file connection
    header <- readLines( con = con, n = head.lines - 1L )
    close( con )

    # extract the column names from the header information
    column.names <- gsub( ".*colname:|}.*", "", header )

    return( column.names )
}
