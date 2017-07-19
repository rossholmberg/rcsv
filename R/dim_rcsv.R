
#'
#' @title dim_rcsv
#' @description retrieve the dimensions of a table stored in an rcsv file
#' @details retrieve dimensions of a table stored in an rcsv file,
#' without loading the entire dataset into memory
#'
#' @return named integer vector of length 2. "rows" and "cols"
#'
#' @param file file path from which the rscv will be read
#'
#' @export

dim_rcsv <- function( file ) {

    # read in a single line, this will contain the number of header lines
    con <- file( file, "r" )
    head.line <- readLines( con = con, n = 1 )
    close( con )

    # check for the tag verifying this file as an rcsv file
    if( !grepl( "rcsvHeader", head.line ) ) {
        stop( "This is not an rcsv file, consider using a different file reader." )
    }

    nrows <- as.integer( gsub( ".*\\{tablerows:|\\}.*", "", head.line ) )
    ncols <- as.integer( gsub( ".*\\{colreflines:|\\}.*", "", head.line ) )

    return( c( rows = nrows, cols = ncols ) )

}
