
#'
#' @title notes_rcsv
#' @description extract notes from an rcsv file
#' @details extract notes from an rcsv file without loading
#' the entire file into memory
#'
#' @param file file path from which the rscv will be read
#'
#' @export


notes_rcsv <- function( file ) {
    # open a connection to the file
    con <- file( file, "r" )

    # read in a single line, this will contain the number of header lines
    head.line <- readLines( con = con, n = 1 )

    # check for the tag verifying this file as an rcsv file
    if( !grepl( "rcsvHeader", head.line ) ) {
        stop( "This is not an rcsv file, consider using a different file reader." )
    }

    notes.lines.num <- as.integer( gsub( ".*noteslines:|}.*", "", head.line ) )
    notes <- readLines( con = con, n = notes.lines.num )

    close( con )

    notes <- gsub( ".*notes:|}.*", "", notes )

    cat( "Note: ", paste( notes, collapse = "\n\t" ) )

    return( invisible( notes ) )

}
