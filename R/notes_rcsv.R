
#'
#' @title notes_rcsv
#' @description extract notes from an rcsv file or object
#' @details display dataset notes, extracting from an rcsv file if necessary,
#' without loading the entire file into memory
#'
#' @param x object name or file path from which the rscv will be read
#'
#' @export


notes_rcsv <- function( x ) {

    if( is.character( x ) ) {

        # open a connection to the file
        con <- file( x, "r" )

        # read in a single line, this will contain the number of header lines
        head.line <- readLines( con = con, n = 1 )

        # check for the tag verifying this file as an rcsv file
        if( !grepl( "rcsvHeader", head.line ) ) {
            stop( "This is not an rcsv file, consider using a different file reader." )
        }

        head.lines.num <- as.integer( gsub( ".*\\{headlines:|\\}.*", "", head.line ) )
        notes <- readLines( con = con, n = head.lines.num - 1L )

        close( con )

        notes <- notes[ grepl( "\\{notes:", notes ) ]
        notes <- gsub( ".*\\{notes:|\\}.*", "", notes )

    } else {
        notes <- attr( x, "notes" )
    }

    cat( "Notes:  ", paste( notes, collapse = "\n\t" ) )

    return( invisible( notes ) )

}
