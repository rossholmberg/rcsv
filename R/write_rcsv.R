write_rcsv <- function( table, file ) {

    # make sure the table object qualifies as a data frame
    if( !"data.frame" %chin% class( table ) ) {
        convert.DT.attempt <- try( setDT( table ), silent = TRUE )
        if( class( convert.DT.attempt ) == "try-error" ) {
            stop( "Object for writing could not be converted to a data frame." )
        } else {
            warning( "Object has been coerced to data frame for writing as rcsv." )
        }
    }

    # convert to data.table if not already
    if( !is.data.table( table ) ) setDT( table )

    # find the current class of each column
    column.classes <- lapply( table, class )
    column.classes <- sapply( column.classes, "[", 1L )

    # work specifically on any list columns
    for( col in which( column.classes == "list" ) ) {

        # make sure all list elements are vectors, and not lists themselves
        element.listCheck <- sapply( table[[ col ]],
                                 function(x) { !is.vector( x ) || is.list( x ) }

        )
        if( any( element.listCheck ) ) {
            stop( paste( "Column", names( table )[ col ], "contains either non vector or list elements.",
                         "\nrcsv does not support this column type." ) )
        }

        # find the class/classes of list elements
        list.class <- sapply( table[[ col ]], class ) %>%
            unique()

        # make sure the list has a consistent class, otherwise coerce to character class and warn
        if( length( list.class ) == 1L ) {
            column.classes[ col ] <- paste0( column.classes[ col ], "(", list.class, ")" )
        } else {
            warning( paste( "List column", names( table )[ col ], "is not of a consistent class.",
                            "\nWill be written as character." ) )
            column.classes[ col ] <- paste0( column.classes[ col ], "(character)" )
            table[ , ( col ) := lapply( .SD[[col]], as, Class = "character" ) ]
        }
    }

    # create a line of text to start the output file.
    # this will be used when reading the file back into R
    head.line <- paste( column.classes, collapse = "," )
    head.line <- paste0( "#head:", head.line, "\n" )

    # write the head line to the output file
    cat( head.line, file = file, append = FALSE )

    # now write the data out, appending below the head line
    fwrite( table,
            file = file,
            append = TRUE,
            sep = ",", sep2 = c( "", "|", "" ),
            dateTimeAs = "write.csv",
            col.names = TRUE
    )

}
