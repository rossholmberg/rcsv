
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
#'
#' @export

glimpse_rcsv <- function( file, width = 80 ) {

    input <- head_rcsv( file, width / 2 - 19L )

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

    col.classes[ col.classes == "integer" ] <- "int"
    col.classes[ col.classes == "character" ] <- "char"
    col.classes[ col.classes == "nueric" ] <- "dbl"
    col.classes[ col.classes == "logical" ] <- "lgic"
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

    cat( paste( strings, collapse = "\n" ), "\n" )

    return( invisible( TRUE ) )

}
