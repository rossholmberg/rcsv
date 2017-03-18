
library( data.table )

n <- 100
dt1 <- data.table( int = seq_len( n ),
                   num = round( rnorm( n ), 5 ),
                   lets = letters[ rep_len( seq_len( 26 ), n ) ],
                   lst = lapply( seq_len( n ), seq_len ),
                   lst.dts = lapply( seq_len( n ), function(x) seq.Date( from = Sys.Date(), by = 1L, length.out = x ) ),
                   lst.psx = lapply( seq_len( n ), function(x) seq.POSIXt( from = Sys.time(), by = 10L, length.out = x ) ),
                   lst.tms = lapply( seq_len( n ), function(x) chron::times( round( seq.int( 0, 0.99, length.out = x ), 4 ) ) )
)
dt3 <- copy(dt1)

# write the table out to rcsv file
write_rcsv( dt3, "~/Desktop/test.rcsv" )

# read back in again
dt2 <- read_rcsv( file = "~/Desktop/test.rcsv" )

identical( dt1, dt2 ) # result is FALSE, maybe because can't compare list objects?
all.equal( dt1, dt2 )
for( i in seq_along( dt1 ) ) { print( identical( dt1[[i]], dt2[[i]] ) ) }
# all column classes are correct
identical( sapply( dt1, class ), sapply( dt2, class ) )

# all list element classes are correct
identical( unlist( lapply( dt1, function(x) lapply( x, class ) ) ),
           unlist( lapply( dt2, function(x) lapply( x, class ) ) )
)
