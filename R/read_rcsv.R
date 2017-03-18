#' @title
#'
#' @param file character extension of file from which to read
#'
#' @export
#'
#' @import data.table
#' @importFrom chron chron
#'


read_rcsv <- function( file ) {

    head.line <- readLines( con = file, n = 1 )
    head.line <- sub( "^#head:", "", head.line )
    column.classes <- strsplit( head.line, split = "," )
    column.classes <- unlist( column.classes )

    output <- fread( file = file,
                     skip = 1L,
                     sep = ",", sep2 = c( "", "|", "" ),
                     colClasses = rep( "character", times = length( column.classes ) )
    )

    # adjust all non-list columns to the classes they should be
    for( col in which( !grepl( "list", column.classes ) ) ) {
        output[ , ( col ) := switch( EXPR = column.classes[ col ],
                                     "Date" = as.Date( .SD[[col]], format = "%Y-%m-%d" ),
                                     "POSIXct" = as.POSIXct( .SD[[col]], format = "%Y-%m-%d %H:%M:%S" ),
                                     "times" = chron::times( as.numeric( .SD[[col]] ) ),
                                     as( .SD[[col]], column.classes[ col ] )
        ) ]
    }

    # adjust list columns to make list elements the classes they should be
    for( col in which( grepl( "^list", column.classes ) ) ) {
        # split the list elements
        output[ , ( col ) := sapply( .SD[[col]], strsplit, split = "\\|" ) ]
        # read the class for list elements from the head line
        list.class <- gsub( "^list\\(|\\)$", "", column.classes[ col ] )

        output[ , ( col ) := switch( EXPR = list.class,
                                     "Date" = sapply( .SD[[col]], function(x) {
                                         x <- as.numeric( x )
                                         as.Date( x, origin = "1970-01-01 00:00:00" )
                                     } ),
                                     "POSIXct" = sapply( .SD[[col]], as.POSIXct, format = "%Y-%m-%d %H:%M:%S" ),
                                     "times" = sapply( output[[col]], function(x) {
                                         x <- as.numeric( x )
                                         chron::chron( times. = x, out.format = "h:m:s" )
                                     } ),
                                     sapply( .SD[[col]], function(x) {
                                         as( x, list.class )
                                     } ) ) ]
    }

    return( output )

}
