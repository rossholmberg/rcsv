
#'
#' @title notes_replace
#' @description add a note to an object, deleting any existing notes
#' @details add a note to an object, deleting any existing notes.
#' Specifically intended for use with objects being stored as `rcsv`
#'
#' @param x object to which the note will be added
#' @param notes character vector of notes
#'
#' @export

notes_replace <- function( x, notes ) {

    setattr( x, "notes", NULL )

    notes_add( x, notes )

}
