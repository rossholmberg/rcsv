read_rcsv <- function( file ) {

    head.line <- readLines( con = file, n = 1 )
    head.lines <- as.integer( gsub( ".*headlines:|}.*", "", head.line ) )
    body.rows <- as.integer( gsub( ".*bodyrows:|}.*", "", head.line ) )

    header <- readLines( con = file, n = head.lines )[ -1L ]

    column.names <- gsub( ".*colname:|}.*", "", header )

    column.classes <- gsub( ".*colclass:|}.*", "", header )

    column.classes.readin <- column.classes
    column.classes.tofollowup <- which( column.classes.readin %chin% c( "POSIXct", "Date", "factor", "times" ) )
    column.classes.readin[ column.classes.tofollowup ] <- "character"

    output <- fread( file = file,
                     skip = head.lines,
                     col.names = column.names,
                     sep = ",", sep2 = c( "", "|", "" ),
                     colClasses = column.classes.readin
    )

    # adjust all non-list columns to the classes they should be
    for( col in column.classes.tofollowup ) {
        col.class <- column.classes[ col ]
        if( col.class == "Date" ) {
            output[ , ( col ) := as.Date( .SD[[col]], format = "%Y-%m-%d" ) ]

        } else if( col.class == "POSIXct" ) {
            tz <- gsub( ".*tz:|}.*", "", header[ col ] )
            if( tz == "none" ) {
                warning( paste0( "Timezone is not set for POSIXct column: `",
                                 column.names[ col ],
                                 "`. Beware of possible consequences." )
                )
                output[ , ( col ) := as.POSIXct( .SD[[col]], format = "%Y-%m-%d %H:%M:%S" ) ]
            } else {
                output[ , ( col ) := as.POSIXct( .SD[[col]], format = "%Y-%m-%d %H:%M:%S", tz = tz ) ]
            }

        } else if( col.class == "times" ) {
            output[ , ( col ) := chron::times( .SD[[col]] ) ]

        } else if( col.class == "factor" ) {
            factor.levels <- gsub( ".*levels:|}.*", "", header[ col ] )
            factor.levels <- unlist( strsplit( factor.levels, "," ) )
            output[ , ( col ) := factor( .SD[[col]], levels = factor.levels ) ]
        }

    }

    # adjust list columns to make list elements the classes they should be
    # for( col in which( grepl( "^list", column.classes ) ) ) {
    #     # split the list elements
    #     output[ , ( col ) := sapply( .SD[[col]], strsplit, split = "\\|" ) ]
    #     # read the class for list elements from the head line
    #     list.class <- gsub( "^list\\(|\\)$", "", column.classes[ col ] )
    #
    #     output[ , ( col ) := switch( EXPR = list.class,
    #                                  "Date" = sapply( .SD[[col]], as.Date, format = "%Y-%m-%d" ),
    #                                  "POSIXct" = sapply( .SD[[col]], as.POSIXct, format = "%Y-%m-%d %H:%M:%S" ),
    #                                  "times" = sapply( .SD[[col]], function(x) {
    #                                      if( is.na( suppressWarnings( as.numeric( x[1] ) ) ) ) {
    #                                          chron::chron( times. = x, format = "h:m:s", out.format = "h:m:s" )
    #                                      } else {
    #                                          chron::chron( times. = x, out.format = "h:m:s" )
    #                                      }
    #                                  } ),
    #                                  sapply( .SD[[col]], function(x) {
    #                                      as( x, list.class )
    #                                  } ) ) ]
    # }

    return( output )

}
