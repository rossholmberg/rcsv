read_rcsv <- function( file ) {

    head.line <- readLines( con = file, n = 1 )
    head.line <- sub( "^#head:", "", head.line )
    column.classes <- strsplit( head.line, split = "," ) %>%
        unlist()

    output <- fread( file = file,
                     skip = 1L,
                     sep = ",", sep2 = c( "", "|", "" ),
                     colClasses = column.classes )

    # adjust all non-list columns to the classes they should be
    for( col in which( !grepl( "list", column.classes ) ) ) {
        output[ , ( col ) := switch( EXPR = column.classes[ col ],
                                     "Date" = as.Date( .SD[[col]], format = "%Y-%m-%d" ),
                                     "POSIXct" = as.POSIXct( .SD[[col]], format = "%Y-%m-%d %H:%M:%S" ),
                                     "times" = chron::times( .SD[[col]] ),
                                     as( .SD[[col]], column.classes[ col ] )
        ) ]
    }

    # adjust list columns to make list elements the classes they should be
    for( col in which( grepl( "list", column.classes ) ) ) {
        output[ , ( col ) := sapply( .SD[[col]], strsplit, split = "\\|" ) ]
        list.class <- gsub( "^list\\(|\\)$", "", column.classes[ col ] )
        output[ , ( col ) := switch( EXPR = list.class,
                                     "Date" = sapply( .SD[[col]], function(x) {
                                         as.Date( x, format = "%Y-%m-%d" )
                                     } ),
                                     "POSIXct" = sapply( .SD[[col]], function(x) {
                                         as.POSIXct( x, format = "%Y-%m-%d %H:%M:%S" )
                                     } ),
                                     "times" = sapply( .SD[[col]], function(x) {
                                         chron::times( x )
                                     } ),
                                     sapply( .SD[[col]], function(x) {
                                         as( x, list.class )
                                     } ) ) ]
    }

    return( output )

}