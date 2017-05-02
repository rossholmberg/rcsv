#'
#' @title read_rcsv
#' @description an extension of the csv file format
#' @details  read an rcsv file, an extension of csv, with column format details
#' stored in a header for more consistent reading into R
#'
#' @param file file path to which the rscv will be written
#'
#' @import data.table
#' @importFrom chron times
#'
#' @export

read_rcsv <- function( file ) {


    .SD <- NULL

    head.line <- readLines( con = file, n = 1 )

    if( !grepl( "rcsvHeader", head.line ) ) {
        stop( "This is not an rcsv file, consider using a different file reader." )
    }

    head.lines <- as.integer( gsub( ".*headlines:|}.*", "", head.line ) )
    body.rows <- as.integer( gsub( ".*tablerows:|}.*", "", head.line ) )

    header <- readLines( con = file, n = head.lines )[ -1L ]

    column.names <- gsub( ".*colname:|}.*", "", header )

    column.classes <- gsub( ".*colclass:|}.*", "", header )

    column.classes.readin <- column.classes
    column.classes.tofollowup <- which( column.classes.readin %chin%
                                            c( "POSIXct", "Date", "factor", "times", "ITime" ) )
    column.classes.readin[ column.classes.tofollowup ] <- "character"

    output <- data.table::fread( file = file,
                                 skip = head.lines,
                                 col.names = column.names,
                                 sep = ",", sep2 = c( "", "|", "" ),
                                 colClasses = column.classes.readin
    )

    # adjust all non-list columns to the classes they should be
    for( col in column.classes.tofollowup ) {
        col.class <- column.classes[ col ]
        convert.from <- gsub( ".*from:|}.*", "", header[ col ] )

        if( col.class == "Date" ) {

            if( convert.from == "integer" ) {
                output[ , ( col ) := as.Date( as.integer( .SD[[col]] ),
                                              origin = "1970-01-01" ) ]
            } else if( convert.from == "string" ) {
                output[ , ( col ) := as.Date( .SD[[col]], format = "%Y-%m-%d" ) ]
            } else {
                warning( paste0( "Don't know how to convert Date column `",
                                 column.names[ col ],
                                 "` from class ",
                                 convert.from, " to ", col.class, "." )
                )
            }

        } else if( col.class == "POSIXct" ) {
            tz <- gsub( ".*tz:|}.*", "", header[ col ] )

            if( convert.from == "string" ) {
                if( tz == "none" ) {
                    warning( paste0( "Timezone is not set for POSIXct column: `",
                                     column.names[ col ],
                                     "`. Beware of possible consequences." )
                    )
                    output[ , ( col ) := as.POSIXct( .SD[[col]],
                                                     format = "%Y-%m-%d %H:%M:%S" ) ]
                } else {
                    output[ , ( col ) := as.POSIXct( .SD[[col]],
                                                     format = "%Y-%m-%d %H:%M:%S",
                                                     tz = tz ) ]
                }
            } else if( convert.from == "integer" ) {
                if( tz == "none" ) {
                    warning( paste0( "Timezone is not set for POSIXct column: `",
                                     column.names[ col ],
                                     "`. Beware of possible consequences." )
                    )
                    output[ , ( col ) := as.POSIXct( as.integer( .SD[[col]] ),
                                                     origin = "1970-01-01 00:00:00" ) ]
                } else {
                    output[ , ( col ) := as.POSIXct( as.integer( .SD[[col]] ),
                                                     origin = "1970-01-01 00:00:00",
                                                     tz = tz ) ]
                }
            } else {
                warning( paste0( "Don't know how to convert POSIXct column `",
                                 column.names[ col ],
                                 "` from class ",
                                 convert.from, " to ", col.class, "." )
                )
            }



        } else if( col.class == "times" ) {

            if( convert.from == "string" ) {
                output[ , ( col ) := chron::times( .SD[[col]] ) ]
            } else if( convert.from == "numeric" ) {
                output[ , ( col ) := chron::times( as.numeric( .SD[[col]] ) ) ]
            } else {
                warning( paste0( "Don't know how to convert times column `",
                                 column.names[ col ],
                                 "` from class ",
                                 convert.from, " to ", col.class, "." )
                )
            }

        } else if( col.class == "ITime" ) {

            if( convert.from == "string" ) {
                output[ , ( col ) := as.ITime( .SD[[col]] ) ]
            } else if( convert.from == "integer" ) {
                output[ , ( col ) := setattr( as.integer( .SD[[col]] ),
                                              "class",
                                              "ITime" ) ]
            } else {
                warning( paste0( "Don't know how to convert ITime column `",
                                 column.names[ col ],
                                 "` from class ",
                                 convert.from, " to ", col.class, "." )
                )
            }

        } else if( col.class == "factor" ) {

            factor.levels <- gsub( ".*levels:|}.*", "", header[ col ] )
            factor.levels <- unlist( strsplit( factor.levels, "," ) )

            if( convert.from == "string" ) {
                output[ , ( col ) := factor( .SD[[col]], levels = factor.levels ) ]
            } else if( convert.from == "integer" ) {
                output[ , ( col ) := factor( as.integer( .SD[[col]] ),
                                             labels = factor.levels ) ]
            }

        }

    }

    # also follow up on character columns still needing conversion
    char.cols <- which( column.classes == "character" )
    convert.from <- gsub( ".*from:|}.*", "", header[ char.cols ] )
    for( col in char.cols[ convert.from == "factorints" ] ) {
        factor.levels <- gsub( ".*levels:|}.*", "", header[ col ] )
        factor.levels <- unlist( strsplit( factor.levels, "," ) )
        output[ , ( col ) := as.integer( .SD[[col]] ) ]
        output[ , ( col ) := factor( .SD[[col]], labels = factor.levels ) ]
        output[ , ( col ) := as.character( .SD[[col]] ) ]
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


    # # before returning to the user, check that all columns are now in the correct format
    # output.col.classes <- lapply( output, class )
    # output.col.classes <- sapply( output.col.classes, "[", 1L )
    #
    # # coerce any remaining columns to their appropriate format
    # columns.toconvert <- which( output.col.classes != column.classes )
    # for( col in columns.toconvert ) {
    #     output[ , ( col ) := as( .SD[[col]], column.classes[ col ] ) ]
    # }


    return( output )

}
