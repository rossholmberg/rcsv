
#'
#' @title notes_add
#' @description add to an existing object note
#' @details add a note to an object, retaining any existing notes.
#' Specifically intended for use with objects being stored as `rcsv`
#'
#' @param x object to which the note will be added
#' @param notes character vector of notes to add
#'
#' @export

notes_add <- function( x, notes ) {

    current <- attr( x, "notes" )

    if( grepl( "\\{|\\}", notes ) ) {
        warning( "Sorry, curly braces ('{' and '}') are reserved characters, so they're being replaced with square ones." )
        notes <- gsub( "\\{", "[", notes )
        notes <- gsub( "\\}", "]", notes )
    }

    setattr( x, "notes", c( current, notes ) )

    cat( "Notes:  ", paste( c( current, notes ), collapse = "\n\t" ) )

}
