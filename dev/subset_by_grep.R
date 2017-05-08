
file <- "READMEfiles/rcsv_noconvert.rcsv"
pattern <- "a"
colname <- "letters"

con <- file( file, "r" )
header <- readLines( con, 1 )
lines.toread <- gsub( ".*\\{headlines:|\\}.*", "", header )
lines.toread <- as.integer( lines.toread ) - 1L
header <- c( header, readLines( con, lines.toread ) )
close( con )

col.header <- header[ grep( paste0( "colname:", colname ), header ) ]
colnum <- as.integer( gsub( ".*\\{colref:|\\}.*", "", col.header ) )

total.columns <- sum( grepl( ".*\\{colname:", header ) )

grep.pattern <- rep( ".*", total.columns )



pattern.length <- nchar( pattern )

if( substr( pattern, 0L, 1L ) != "^" ) {
    pattern <- paste0( ".*", pattern )
} else {
    pattern <- substr( pattern, 2, pattern.length )
}

if( substr( pattern, pattern.length, pattern.length ) != "$" ) {
    pattern <- paste0( pattern, ".*" )
} else {
    pattern <- substr( pattern, 0L, pattern.length - 1L )
}


grep.pattern[ colnum ] <- pattern

grep.pattern <- paste( grep.pattern, collapse = "," )

fread( paste( "grep", grep.pattern, file ), skip = lines.toread + 1L )
fread( paste( "grep", grep.pattern, file )
