#'
#' @title read_rcsv
#' @description an extension of the csv file format
#' @details  read an rcsv file, an extension of csv, with column format details
#' stored in a header for more consistent reading into R
#'
#' @param file file path to which the rscv will be written
#' @param subset integer vector of rows to read
#' @param echo.notes print notes to the console on import?
#' @import data.table
#' @importFrom chron times
#' @importFrom fasttime fastPOSIXct
#'
#' @export

read_rcsv <- function( file, subset = NULL, echo.notes = TRUE ) {

    .SD <- notes <- NULL

    # open a connection to the file
    con <- file( file, "r" )

    # read in a single line, this will contain the number of header lines
    head.line <- readLines( con = con, n = 1 )

    # check for the tag verifying this file as an rcsv file
    if( !grepl( "rcsvHeader", head.line ) ) {
        stop( "This is not an rcsv file, consider using a different file reader." )
    }

    head.lines <- as.integer( gsub( ".*headlines:|}.*", "", head.line ) )
    colref.lines <- as.integer( gsub( ".*colreflines:|}.*", "", head.line ) )
    if( grepl( "notes", head.line ) ) {
        notes.lines <- as.integer( gsub( ".*noteslines:|}.*", "", head.line ) )
        notes <- readLines( con = con, n = notes.lines )
    }

    body.rows <- as.integer( gsub( ".*tablerows:|}.*", "", head.line ) )

    # read in the header, and close the file connection
    header <- readLines( con = con, n = colref.lines )
    close( con )
    header.forinput <- header

#     # subset columns if requested
#     if( !is.null( select ) ) {
#         ncols <- length( column.names )
#         if( is.numeric( select ) ) {
#             if( max( select ) > ncols ) {
#                 stop( paste( "Selected column numbers out of range.\n",
#                              ncols, " columns available.\n",
#                              "Column names: ", column.names ) )
#             }
#         } else if( is.character( select ) ) {
#             # make sure all requested columns are available
#             if( sum( !select %chin% column.names ) > 0 ) {
#                 stop( sprintf(
#                     "Columns %s not available in file.",
#                     paste( column.names[ !select %chin% column.names ],
#                            collapse = ", " )
#                 ) )
#             } else {
#                 select <- match( select, column.names )
#             }
#         }
#         header <- header[ select ]
#     }

    column.names <- gsub( ".*colname:|}.*", "", header.forinput )

    column.classes <- gsub( ".*colclass:|}.*", "", header.forinput )

    cols.toconvert <- grep( "\\{from:", header.forinput )

    column.classes.readin <- column.classes
    column.classes.readin[ cols.toconvert ] <-
        gsub( ".*from:|}.*", "",
              header.forinput[ grepl( "\\{from:", header.forinput ) ] )
    # a few particular `from` parameters should be read in differently to how
    # they're passed
    column.classes.readin[ column.classes.readin == "factorints" ] <- "integer"
    column.classes.readin[ column.classes.readin %in% c( "short", "long" ) ] <- "character"

    # column.classes.tofollowup <- which( column.classes.readin %chin%
    #                                         c( "POSIXct", "Date", "factor",
    #                                            "times", "ITime", "logical" ) )
    # column.classes.readin[ column.classes.tofollowup ] <- "character"

    if( !is.null( subset ) ) {
        skip.lines <- head.lines + min( subset )
        nrows <- max( subset ) - min( subset ) + 1L
        subset <- subset - min( subset ) + 1L
    } else {
        skip.lines <- head.lines + 1L
        nrows <- -1L
    }



    output <- data.table::fread( file = file,
                                 skip = skip.lines,
                                 col.names = column.names,
                                 sep = ",", sep2 = c( "", "|", "" ),
                                 colClasses = column.classes.readin,
                                 nrows = nrows,
                                 header = FALSE,
                                 showProgress = TRUE
    )

    if( !is.null( subset ) ) {
        output <- output[ subset, ]
    }

    # adjust all non-list columns to the classes they should be
    for( col in cols.toconvert ) {
        col.class <- column.classes[ col ]
        convert.from <- gsub( ".*from:|}.*", "", header[ col ] )

        if( col.class == "Date" ) {

            if( convert.from == "integer" ) {
                output[ , ( col ) := as.Date( as.integer( .SD[[col]] ),
                                              origin = "1970-01-01" ) ]
            } else if( convert.from == "string" ) {
                output[ , ( col ) := as_Date( .SD[[col]] ) ]
            } else {
                warning( paste0( "Don't know how to convert Date column `",
                                 column.names[ col ],
                                 "` from class ",
                                 convert.from, " to ", col.class, "." )
                )
            }

        } else if( col.class == "POSIXct" ) {
            tz <- gsub( ".*tz:|}.*", "", header[ col ] )
            tzoffset <- as.numeric( gsub( ".*tzoffset:|}.*", "", header[ col ] ) )

            if( convert.from == "string" ) {
                if( tz == "none" && { is.null( tzoffset ) || is.na( tzoffset ) } ) {
                    warning( paste0( "Timezone is not set for POSIXct column: `",
                                     column.names[ col ],
                                     "`. Beware of possible consequences." )
                    )
                    output[ , ( col ) := fasttime::fastPOSIXct( .SD[[col]], tz = "UTC" ) ]
                } else if( tz %chin% c( "UTC", "GMT" ) ) {
                    output[ , ( col ) := fasttime::fastPOSIXct( .SD[[col]], tz = tz ) ]
                } else {
                    output[ , ( col ) := as_posix( .SD[[col]], tz = tz ) ]
                }
            } else if( convert.from == "integer" ) {
                if( tz == "none" ) {
                    warning( paste0( "Timezone is not set for POSIXct column: `",
                                     column.names[ col ],
                                     "`. Beware of possible consequences." )
                    )
                    output[ , ( col ) := as.POSIXct( .SD[[col]],
                                                     origin = "1970-01-01 00:00:00",
                                                     tz = "UTC" ) ]
                } else {
                    output[ , ( col ) := as.POSIXct( .SD[[col]],
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



        } else if( col.class == "logical" ) {

            if( convert.from %chin% c( "long", "short", "integer" ) ) {
                output[ , ( col ) := as.logical( .SD[[col]] ) ]
            } else {
                warning( paste0( "Don't know how to convert logical column `",
                                 column.names[ col ],
                                 "` from class ",
                                 convert.from, " to ", col.class, "." )
                )
            }

        } else if( col.class == "times" ) {

            if( convert.from == "string" ) {
                output[ , ( col ) := as_times( .SD[[col]] ) ]
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
                output[ , ( col ) := as_ITime( .SD[[col]] ) ]
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
            # subset the factor levels to only those present in this subset
            if( !is.null( subset ) ) {
                factor.levels <- factor.levels[ factor.levels %chin% output[[col]] ]
            }

            if( convert.from == "string" ) {
                output[ , ( col ) := factor( .SD[[col]], levels = factor.levels ) ]
            } else if( convert.from == "integer" ) {
                output[ , ( col ) := factor( as.integer( .SD[[col]] ),
                                             labels = factor.levels ) ]
            }

        } else if( col.class == "character" && convert.from == "factorints" ) {
            factor.levels <- gsub( ".*levels:|}.*", "", header[ col ] )
            factor.levels <- unlist( strsplit( factor.levels, "," ) )
            # subset the factor levels to only those present in this subset
            if( !is.null( subset ) ) {
                factor.levels <- factor.levels[ sort( unique( as.integer( output[[col]] ) ) ) ]
            }
            output[ , ( col ) := factor( .SD[[col]], labels = factor.levels ) ]
            output[ , ( col ) := as.character( .SD[[col]] ) ]
        }

    }

    # add any notes as an attribute before returning to the user
    if( !is.null( notes ) ) {
        notes <- gsub( ".*notes:|}.*", "", notes )
        setattr( output, "notes", notes )

        # also print those notes to the console if requested
        if( echo.notes ) {
            cat( "Notes: ", paste( notes, collapse = "\n\t" ), "\n" )
        }

    }


    return( output )

}
