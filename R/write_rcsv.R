#'
#'
#' @param x data frame object to write out
#' @param file character extension of file to write to
#'
#' @export
#'
#' @import data.table
#'





write_rcsv <- function( df, file ) {

    # make sure the input object qualifies as a data frame
    if( !"data.frame" %chin% class( df ) ) {
        stop( "Object is not a data frame. rcsv currently only works with data frames." )
    }

    # make a copy of the object to prevent issues with in-place column manipulation
    x <- data.table::copy( df )

    # convert to data.table if not already
    if( !data.table::is.data.table( x ) ) {
        data.table::setDT( x )
    }

    # find the current class of each column
    column.classes <- lapply( x, class )
    column.classes <- sapply( column.classes, "[", 1L )

    # work specifically on any list columns
    for( col in which( column.classes == "list" ) ) {

        # make sure all list elements are vectors, and not lists themselves
        element.listCheck <- sapply( x[[ col ]],
                                 function(x) {
                                     { is.vector( x ) && !is.list( x ) } ||
                                         class( x )[1] %chin% c( "Date", "POSIXct", "times" )
                                 }
        )

        # stop if there are any columns we can't work with
        if( any( !element.listCheck ) ) {
            stop( paste( "Column", names( x )[ col ],
                         "contains either non-vector or list elements.",
                         "\nSorry, rcsv does not currently support this column type." )
            )
        }

        # find the class/classes of list elements
        list.class <- lapply( x[[ col ]], class )
        list.class <- sapply( list.class, "[", 1L )
        list.class <- unique( list.class )
        # make sure the list has a consistent class, otherwise coerce to character class and warn
        if( length( list.class ) == 1L ) {

            # special case for times class. Make sure no values > 1
            # (ie: later than midnight, but no date value is specified.)
            if( list.class == "times" ) {
                if( max( as.numeric( unlist( x[[ col ]] ) ) ) > 1 ) {
                    stop( paste( "Column", names( x )[ col ], "of class `times` contains values
                                greater than 1 (ie: later than midnight, with no date value specified.",
                                 "\nThese values won't be saved and read properly.",
                                 "\nConsider coercing this column to a different class." ) )
                }
                # convert times to numeric to avoid rounding errors
                x[ , ( col ) := lapply( .SD[[ ( col ) ]], as, Class = "numeric" ) ]
            }

            # special case for times class. Make sure no values > 1
            # (ie: later than midnight, but no date value is specified.)
            if( list.class == "Date" ) {
                # convert dates to numeric to avoid rounding errors
                x[ , ( col ) := lapply( .SD[[ ( col ) ]], as, Class = "numeric" ) ]
            }

            column.classes[ col ] <- paste0( column.classes[ col ], "(", list.class, ")" )
            x[ , ( col ) := lapply( .SD[[ ( col ) ]], as, Class = "character" ) ]
        } else {
            warning( paste( "List column", names( x )[ col ], "is not of a consistent class.",
                            "\nWill be written as character class." ) )
            column.classes[ col ] <- paste0( column.classes[ col ], "(character)" )
            x[ , ( col ) := lapply( .SD[[ ( col ) ]], as, Class = "character" ) ]
            list.class <- "character"
        }

    }

    # create a line of text to start the output file.
    # this will be used when reading the file back into R
    head.line <- paste( column.classes, collapse = "," )
    head.line <- paste0( "#head:", head.line, "\n" )

    # write the head line to the output file
    cat( head.line, file = file, append = FALSE )

    # now write the data out, appending below the head line
    fwrite( x,
            file = file,
            append = TRUE,
            sep = ",", sep2 = c( "", "|", "" ),
            dateTimeAs = "write.csv",
            col.names = TRUE
    )

}
