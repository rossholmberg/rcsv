
#'
#' @title glimpse_rcsv
#' @description display a short summary of the contents of an rcsv
#' file without loading the entire dataset, similar to
#' dplyr::glimpse for a data frame in memory
#'
#' @details read in and print the `head` of an rcsv file. For
#' viewing data, not to be used for data input
#'
#' @param file file path to which the rscv will be written
#' @param width integer, approximate character length of each line
#' of the output display
#' @param echo logical, echo the glimpse (TRUE), or just silently return details (FALSE)
#'
#' @export

glimpse_rcsv <- function( file, width = 80, echo = TRUE ) {


    # open a connection to the file
    con <- file( file, "r" )
    # read in a single line, this will contain a few basic table details
    head.line <- readLines( con = con, n = 1 )
    headlines.num <- as.integer( gsub( ".*\\{headlines:|\\}.*", "", head.line ) )
    head.lines <- readLines( con = con, n = headlines.num - 1L )
    close( con )

    # get the total number of rows in the table
    row.count <- as.integer( gsub( ".*\\{tablerows:|\\}.*", "", head.line ) )

    # read the top of the file
    input <- read_rcsv( file,
                        subset = seq_len( ifelse( width > 50,
                                                  width / 2 - 19L,
                                                  width ) ),
                        echo.notes = FALSE )

    col.names <- names( input )
    col.names.short <- substr( col.names, 0, 9L )
    col.names.short[ nchar( col.names ) > 9L ] <- paste0(
        substr( col.names.short[ nchar( col.names ) > 9L ], 0, 7 ),
        "..."
    )

    col.classes <- vapply( X = input,
                           FUN = function(x){
                               class(x)[1]
                           },
                           FUN.VALUE = character( 1L ) )

    notes <- head.lines[ grepl( "note", head.lines ) ]
    notes <- gsub( ".*\\{notes:|\\}.*", "", notes )

    output <- list(
        dim = c( rows = row.count, cols = ncol( input ) ),
        names = col.names,
        classes = col.classes,
        notes = notes
    )

    col.classes[ col.classes == "integer" ] <- "int"
    col.classes[ col.classes == "character" ] <- "char"
    col.classes[ col.classes == "nueric" ] <- "dbl"
    col.classes[ col.classes == "logical" ] <- "logi"
    col.classes[ col.classes == "Date" ] <- "date"
    col.classes[ col.classes == "POSIXct" ] <- "posx"
    col.classes[ col.classes == "ITime" ] <- "itim"
    col.classes[ col.classes == "IDate" ] <- "idte"
    col.classes[ col.classes == "factor" ] <- "fct"
    col.classes[ col.classes == "times" ] <- "time"
    col.classes <- substr( col.classes, 0, 4 )

    data <- vapply( X = input,
                    FUN = function(x) {
                        paste( x, collapse = "," )
                    },
                    FUN.VALUE = character( 1L )
    )

    strings <- paste0(
        '"', col.names.short, '"',
        " <", col.classes, "> ",
        substr( data, 0, width - 16 ), "..."
    )

    cat( "\n\n",
         paste( "file:\t\t", file ), "\n",
         paste( "total cols:\t", length( data ) ), "\n",
         paste( "total rows:\t", row.count ), "\n\n",
         "Notes:\t\t",
         paste( notes, collapse = "\n\t\t " ), "\n\n",
         # "----- DATA FOLLOWS ----- :\n",
         paste( strings, collapse = "\n " ), "\n" )

    return( invisible( output ) )

}
