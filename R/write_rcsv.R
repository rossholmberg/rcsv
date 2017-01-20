write_rcsv <- function( table, file ) {

    # make a copy of the input object. This is inefficient in terms of memory,
    # but will prevent data.table making in-place changes to the object.
    input <- data.table::copy( table )

    data.table::setDT( input )

    # make sure the input object qualifies as a data frame
    if( !"data.frame" %chin% class( input ) ) {
        setDT( input )
        # convert.DT.attempt <- try( setDT( input ), silent = TRUE )
        # if( class( convert.DT.attempt ) == "try-error" ) {
            # stop( "Object for writing could not be converted to a data frame." )
        # } else {
            warning( "Object has been coerced to data frame for writing as rcsv." )
        # }
    } else {
        data.table::setDT( input )
    }

    # convert to data.table if not already
    if( !is.data.table( input ) ) setDT( input )

    # find the current class of each column
    column.classes <- lapply( input, class )
    column.classes <- sapply( column.classes, "[", 1L )

    # work specifically on any list columns
    for( col in which( column.classes == "list" ) ) {

        # make sure all list elements are vectors, and not lists themselves
        element.listCheck <- sapply( input[[ col ]],
                                 function(x) {
                                     { is.vector( x ) && !is.list( x ) } ||
                                         class( x ) %chin% c( "Date", "POSIXct", "times" )
                                 }
        )
        if( any( !element.listCheck ) ) {
            stop( paste( "Column", names( input )[ col ], "contains either non vector or list elements.",
                         "\nrcsv does not support this column type." ) )
        }

        # find the class/classes of list elements
        list.class <- sapply( input[[ col ]], class )
        list.class <- unique( list.class[1] )

        # special case for times class. Make sure no values > 1
        # (ie: later than midnight, but no date value is specified.)
        if( list.class == "times" ) {
            if( max( as.numeric( unlist( input[[ col ]] ) ) ) > 1 ) {
                stop( paste( "Column", names( input )[ col ], "of class `times` contains values
                                greater than 1 (ie: later than midnight, with no date value specified.",
                             "\nThese values won't be saved and read properly.",
                             "\nConsider coercing this column to a different class." ) )
            }
        }

        # make sure the list has a consistent class, otherwise coerce to character class and warn
        if( length( list.class ) == 1L ) {
            column.classes[ col ] <- paste0( column.classes[ col ], "(", list.class, ")" )
            input[ , ( col ) := lapply( .SD[[col]], as, Class = "character" ) ]
        } else {
            warning( paste( "List column", names( input )[ col ], "is not of a consistent class.",
                            "\nWill be written as character." ) )
            column.classes[ col ] <- paste0( column.classes[ col ], "(character)" )
            input[ , ( col ) := lapply( .SD[[col]], as, Class = "character" ) ]
        }
    }

    # create a line of text to start the output file.
    # this will be used when reading the file back into R
    head.line <- paste( column.classes, collapse = "," )
    head.line <- paste0( "#head:", head.line, "\n" )

    # write the head line to the output file
    cat( head.line, file = file, append = FALSE )

    # now write the data out, appending below the head line
    fwrite( input,
            file = file,
            append = TRUE,
            sep = ",", sep2 = c( "", "|", "" ),
            dateTimeAs = "write.csv",
            col.names = TRUE
    )

}
