
write_rcsv <- function( table,
                        file,
                        strings.convert = FALSE,
                        strings.as.factor.ints = strings.convert,
                        factors.as.ints = strings.convert,
                        dates.as.ints = strings.convert,
                        posix.as.ints = strings.convert,
                        times.as.num = strings.convert ) {


    # make sure the input object qualifies as a data frame
    if( !"data.frame" %chin% class( table ) ) {
        convert.DT.attempt <- try( data.table::setDT( table ), silent = TRUE )
        if( class( convert.DT.attempt ) == "try-error" ) {
        stop( "Object for writing could not be converted to a data frame." )
        } else {
            warning( "Object has been coerced to data frame for writing as rcsv." )
        }
    } else {
        data.table::setDT( table )
    }

    # make a copy of the input object. This is inefficient in terms of memory,
    # but will prevent data.table making in-place changes to the object.
    input <- data.table::copy( table )

    # define how many lines are to be used in the header, and how many in the body
    head.lines <- ncol( input ) + 1L
    body.rows <- nrow( input )

    # put that into a header line
    head.line.readlines <- paste(
        "rcsvHeader",
        paste0( "headlines:", head.lines ),
        paste0( "tablerows:", body.rows ),
        sep = "},{"
    )

    # find the column names
    column.names <- names( input )
    column.names.header <- paste0( "colname:", column.names )

    # find the current class of each column
    column.classes <- lapply( input, class )
    column.classes <- sapply( column.classes, "[", 1L )
    column.classes.header <- paste0( "colclass:", column.classes )

    # create text header to start the output file.
    # this will be used when reading the file back into R
    header <- paste( column.names.header, column.classes.header, sep = "},{" )

    if( strings.as.factor.ints ) {
        char.cols <- which( column.classes == "character" )
        for( col in char.cols ) {
            input[ , ( col ) := factor( .SD[[col]] ) ]
        }
        levels.char.cols <- lapply(
            X = input[ , char.cols, with = FALSE ],
            FUN = levels
        )
        levels.char.cols <- sapply( levels.char.cols, paste, collapse = "," )
        levels.char.cols <- paste0( "levels:", levels.char.cols )
        for( col in char.cols ) {
            input[ , ( col ) := as.integer( .SD[[col]] ) ]
        }
        header[ char.cols ] <- paste( header[ char.cols ],
                                      levels.char.cols,
                                      "from:factorints",
                                      sep = "},{" )
    }


    # add a levels parameter to any factor columns
    if( "factor" %chin% column.classes ) {
        factor.cols <- which( column.classes == "factor" )
        header.factor.cols <- lapply(
            X = input[ , factor.cols, with = FALSE ],
            FUN = levels
        )
        header.factor.cols <- sapply( header.factor.cols, paste, collapse = "," )
        header.factor.cols <- paste0( "levels:", header.factor.cols )
        if( factors.as.ints ) {
            for( col in factor.cols ) {
                input[ , ( col ) := as.integer( .SD[[col]] ) ]
            }
            header[ factor.cols ] <- paste( header[ factor.cols ],
                                            header.factor.cols,
                                            "from:integer",
                                            sep = "},{" )
        } else {
            header[ factor.cols ] <- paste( header[ factor.cols ],
                                            header.factor.cols,
                                            "from:string",
                                            sep = "},{" )
        }

    }

    # add timezone to any POSIXct columns
    if( "POSIXct" %chin% column.classes ) {
        posix.cols <- which( column.classes == "POSIXct" )
        header.posix.cols <- vapply(
            X = input[ , posix.cols, with = FALSE ],
            FUN = function(x) {
                tz <- attr( x, "tzone" )
                if( !is.null( tz ) ) {
                    return( tz )
                } else {
                    return( "none" )
                }
            },
            FUN.VALUE = vector( "character", length = length( posix.cols ) )
        )
        header.posix.cols <- paste0( "tz:", header.posix.cols )
        if( posix.as.ints ) {
            for( col in posix.cols ) {
                input[ , ( col ) := as.integer( .SD[[col]] ) ]
            }
            header[ posix.cols ] <- paste( header[ posix.cols ],
                                           header.posix.cols,
                                           "from:integer",
                                           sep = "},{" )
        } else {
            header[ posix.cols ] <- paste( header[ posix.cols ],
                                           header.posix.cols,
                                           "from:string",
                                           sep = "},{" )

        }

    }

    # convert any columns of `timeas` class to character before writing
    if( "times" %chin% column.classes ) {
        times.cols <- which( column.classes == "times" )
        if( times.as.num ) {
            for( col in times.cols ) {
                input[ , ( col ) := as.numeric( .SD[[col]] ) ]
            }
            header[ times.cols ] <- paste( header[ times.cols ],
                                           "from:numeric",
                                           sep = "},{" )
        } else {
            for( col in times.cols ) {
                input[ , ( col ) := as.character( .SD[[col]] ) ]
            }
            header[ times.cols ] <- paste( header[ times.cols ],
                                           "from:string",
                                           sep = "},{" )
        }

    }

    if( "Date" %chin% column.classes ) {
        date.cols <- which( column.classes == "Date" )
        if( dates.as.ints ) {
            for( col in date.cols ) {
                input[ , ( col ) := as.integer( .SD[[col]] ) ]
            }
            header[ date.cols ] <- paste( header[ date.cols ],
                                          "from:integer",
                                          sep = "},{" )
        } else {
            for( col in date.cols ) {
                input[ , ( col ) := as.character( .SD[[col]] ) ]
            }
            header[ date.cols ] <- paste( header[ date.cols ],
                                          "from:string",
                                          sep = "},{" )
        }
    }

    # write the header to the output file
    header <- paste0( "#{",
                      c( head.line.readlines,
                         paste0( "colref:", seq_along( input ), "},{", header ) ),
                      "}" )
    cat( header,
         sep = "\n",
         file = file, append = FALSE
    )

    # now write the data out, appending below the head line
    data.table::fwrite( x,
                        file = file,
                        append = TRUE,
                        sep = ",", sep2 = c( "", "|", "" ),
                        dateTimeAs = "write.csv",
                        col.names = TRUE
    )

}
