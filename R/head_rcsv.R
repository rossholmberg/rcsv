
#'
#' @title head_rcsv
#' @description read only the first few lines of an rscv file
#' @details read in the `head` of an rcsv file, without loading the
#' entire file
#'
#' @param file file path from which the rscv will be read
#' @param n integer, number of rows to read
#' @param echo.notes print notes to the console on import?
#'
#' @importFrom utils head
#'
#' @export

head_rcsv <- function( file, n = 6, echo.notes = TRUE ) {

    input <- read_rcsv( file,
                        subset = seq_len( n ),
                        echo.notes )

    utils::head( input, n )

}
