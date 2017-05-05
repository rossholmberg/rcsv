#'
#' @title write_rcsv
#' @description an extension of the csv file format
#' @details write out an rcsv file, an extension of csv, with column format details
#' stored in a header for more consistent reading into R
#'
#' @param table a data.table or data.frame object to write out
#' @param file file path to which the rscv will be written
#' @param strings.convert global switching of storage conversion types
#' @param strings.as.factor.ints logical, convert strings to factors,
#' and write to file as integer. May save space on disk
#' @param factors.as.ints logical, write factor columns to file as
#' integer, with "levels" stored in a header object. May save space on disk
#' @param dates.as.ints logical,  write date columns to file as
#' integer, with "tz" stored in a header object, and origin assumed to be
#' "1970-01-01". May save space on disk
#' @param posix.as.num logical, write POSIXct columns to file as
#' numeric, with "tz" stored in a header object, and origin assumed to be
#' "1970-01-01 00:00:00". May save space on disk
#' @param times.as.num logical, write `chron::times` columns to file as
#' numeric. Allows for sub-second precision to be stored, as opposed to
#' converting times to character, therefore only storing precision to seconds
#' @param ITimes.as.ints logical, write `ITime` columns to file as
#' integers. May save space on disk
#' @param logical.convert one of "int"/TRUE to store as integers, "short" to shorten
#' to "T" or "F", or "long"/FALSE to leave unchanged. May save space on disk
#' @param notes single line of text. Add notes to the dataset. Will be displayed in
#' the console when data is impoted by `read_rcsv`, and stored in the imported data frame
#' as an attribute "notes". By default, any existing "notes" attribute is stored here.
#'
#'
#' @import data.table
#' @importFrom chron times
#'
#' @export

write_rcsv <- function( table,
                        file,
                        strings.convert = FALSE,
                        strings.as.factor.ints = strings.convert,
                        factors.as.ints = strings.convert,
                        dates.as.ints = strings.convert,
                        posix.as.num = strings.convert,
                        times.as.num = strings.convert,
                        ITimes.as.ints = strings.convert,
                        logical.convert = strings.convert,
                        notes = attr( table, "notes" ) ) {

    logical.as.int <- FALSE

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


    # add a shortened form logical if requested
    if( "logical" %chin% column.classes ) {
        logical.cols <- which( column.classes == "logical" )
        if( isTRUE( logical.convert ) ||
            { !is.logical( logical.convert ) &&
            logical.convert %chin% c( "int", "integer", "number", "numeric", "num" ) }
        ) {
            logical.as.int <- TRUE
            header[ logical.cols ] <- paste( header[ logical.cols ],
                                             "from:integer",
                                             sep = "},{" )
        } else if( logical.convert == FALSE || logical.convert %chin% c( "long", "lng" ) ) {
            header[ logical.cols ] <- paste( header[ logical.cols ],
                                             "from:long",
                                             sep = "},{" )
        } else if( logical.convert %chin% c( "short", "shrt" ) ) {
            for( col in logical.cols ) {
                input[ , ( col ) := substr( as.character( .SD[[col]] ), 0, 1 ) ]
            }
            header[ logical.cols ] <- paste( header[ logical.cols ],
                                            "from:short",
                                            sep = "},{" )
        } else {
            stop(
                sprintf( "%s is not a valid input for `logical.convert`", logical.convert )
            )
        }

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
            FUN = attr,
            FUN.VALUE = vector( "character", length = length( posix.cols ) ),
            which = "tzone"
        )
        header.posix.cols[ header.posix.cols == "" ] <- "none"
        header.posix.cols <- paste0( "tz:", header.posix.cols )
        if( posix.as.num ) {
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

    # convert any columns of `times` class to character or numeric before writing
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

    # convert any columns of `ITime` class to character or integer before writing
    if( "ITime" %chin% column.classes ) {
        ITime.cols <- which( column.classes == "ITime" )
        if( ITimes.as.ints ) {
            for( col in ITime.cols ) {
                input[ , ( col ) := as.integer( .SD[[col]] ) ]
            }
            header[ ITime.cols ] <- paste( header[ ITime.cols ],
                                           "from:integer",
                                           sep = "},{" )
        } else {
            for( col in ITime.cols ) {
                input[ , ( col ) := as.character( .SD[[col]] ) ]
            }
            header[ ITime.cols ] <- paste( header[ ITime.cols ],
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



    # also add a `notes` row
    if( is.null( notes ) || length( notes ) == 0L ) {
        notes <- NULL
    } else if( grepl( "\n", notes ) ) {
        # warning( "`notes` is being coerced to a single line" )
        # notes <- gsub( "\n", " ", notes )
        notes <- unlist( strsplit( notes, "\n" ) )
    }

    if( !is.null( notes ) ) {
        notes <- paste0( "notes:", notes )
    }

    # define how many lines are to be used in the header, and how many in the body
    head.lines <- ncol( input ) + 1L + length( notes )
    body.rows <- nrow( input )

    # put that into a header line
    if( !is.null( notes ) ) {
        head.line.readlines <- paste(
            "rcsvHeader",
            paste0( "headlines:", head.lines ),
            paste0( "noteslines:", length( notes ) ),
            paste0( "colreflines:", ncol( input ) ),
            paste0( "tablerows:", body.rows ),
            sep = "},{"
        )
        header <- paste0( "#{",
                          c( head.line.readlines,
                             notes,
                             paste0( "colref:", seq_along( input ), "},{", header ) ),
                          "}" )
    } else {
        head.line.readlines <- paste(
            "rcsvHeader",
            paste0( "headlines:", head.lines ),
            paste0( "colreflines:", ncol( input ) ),
            paste0( "tablerows:", body.rows ),
            sep = "},{"
        )
        header <- paste0( "#{",
                          c( head.line.readlines,
                             paste0( "colref:", seq_along( input ), "},{", header ) ),
                          "}" )
    }


    # write the header to the output file
    cat( header,
         sep = "\n",
         file = file, append = FALSE
    )

    # now write the data out, appending below the head line
    data.table::fwrite( input,
                        file = file,
                        append = TRUE,
                        sep = ",", sep2 = c( "", "|", "" ),
                        dateTimeAs = "write.csv",
                        logicalAsInt = logical.as.int,
                        col.names = TRUE
    )

    if( !is.null( notes ) ) {
        cat( "Notes: ", paste( sub( "^notes:", "", notes ), collapse = "\n\t" ) )
    }

    return( invisible( TRUE ) )

}
