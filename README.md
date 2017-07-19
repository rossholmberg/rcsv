<!-- Do not edit README.md directly, edit README.Rmd instead and re-knit before commit -->
The rcsv format.
----------------

The basic idea behind this format is to add a header section to the regular csv format, containing information about the data frame being stored, in such a way as to allow easy reading and writing of data to and from file, without losing the structure of the original data. Specifically designed for storing data frame (or data table) objects, details stored in the header include the dimensions of the data frame, and the class of each column. This means that the data frame can be read back into memory when required, without the need to specify column classes on input, nor perform column manipulations after import. The data will be brought back into memory in (almost) exactly the form it was in when it was saved.

``` r
library( rcsv )
library( data.table )
library( dplyr )
library( readr )
library( ggplot2 )
```

Why not rds, feather, fst...?
-----------------------------

Personally, I like to work with binary files, and not having to worry about things like classes, timezones, etc. However, these binary formats are often not suitable in certain workflows, for example where collaborators may not be working in R\*. It can also be beneficial in certain workflows to have meaningful diffs when a data file is changed, in order to work with version control systems like git.

So to make the data as generally accessible as possible, and allowing for meaningful diffs, while maintaining the ability to write out and read in data without losing important attributes, is the aim here.

-   `feather` tries to address this with compatibility in both R and python, but this still can't encompass everyone's collaborators.

Testing
-------

### Set up some test data

We'll look at a test data frame, using several different column types. The `rcsv` package is specifically designed to work with the following column types, while others may or may not work well (please do your own testing): character, numeric, integer, logical, factor, Date, POSIXct, ITime, IDate, times

``` r
testDF <- function( n ) {
    data.frame(
        integers = 1:n,
        letters = sample( letters, n, replace = TRUE ),
        dates = sample(
            seq.Date( as.Date( "1970-01-01" ), as.Date( "2199-12-31" ), by = 1 ),
            n, replace = TRUE ),
        posix = as.POSIXct( seq.int( 1E6, by = 1000, length.out = n ), tz = "EST", origin = "1970-01-01 00:00:00" ),
        itime = setattr( sample( seq_len( 86399 ), n, replace = TRUE ), "class", "ITime" ),
        logical = sample( c( TRUE, FALSE ), n, replace = T ),
        factor = factor( sample( c( "small", "medium", "large", "extra-large" ), n, replace = TRUE ),
                         levels = c( "small", "medium", "large", "extra-large" )  ),
        times = chron::times( seq.int( from = 0.001, to = 0.999, length.out = n ) ),
        stringsAsFactors = FALSE
    )
}

set.seed( 123 )
df <- testDF( n = 100 )
glimpse( df, width = 80 )
#> Observations: 100
#> Variables: 8
#> $ integers <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,...
#> $ letters  <chr> "h", "u", "k", "w", "y", "b", "n", "x", "o", "l", "y", "l"...
#> $ dates    <date> 2107-12-31, 2046-07-20, 2082-05-19, 2189-07-12, 2081-01-2...
#> $ posix    <dttm> 1970-01-12 08:46:40, 1970-01-12 09:03:20, 1970-01-12 09:2...
#> $ itime    <S3: ITime> 05:43:46, 23:05:47, 14:25:58, 12:21:39, 09:39:42, 21...
#> $ logical  <lgl> FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, ...
#> $ factor   <fctr> extra-large, small, extra-large, large, medium, medium, l...
#> $ times    <S3: times> 00:01:26, 00:15:57, 00:30:28, 00:44:59, 00:59:30, 01...
```

### Add notes

An important feature of the `rcsv` format is the ability to include notes on the data within the file itself. We'll do that here for demonstration.

``` r
notes_replace( df, "Here's an example note." )
#> Notes:   Here's an example note.
```

``` r
notes_add( df, "And another one." )
#> Notes:   Here's an example note.
#>  And another one.
```

### write\_rcsv with default parameters

A simple call to `write_rcsv` will write out the object to csv as with any csv writing function. The notes are printed to the console on file write.

``` r
testfile <- "READMEfiles/test.rcsv"
write_rcsv( df, testfile )
#> Notes:  Here's an example note.
#>  And another one.
```

Notice that at the top of this file though, is a (JSON-like) header:

``` r
readLines( testfile, n = 15 )
#>  [1] "#{rcsvHeader},{headlines:11},{noteslines:2},{colreflines:8},{tablerows:100}"                         
#>  [2] "#{notes:Here's an example note.}"                                                                    
#>  [3] "#{notes:And another one.}"                                                                           
#>  [4] "#{colref:1},{colname:integers},{colclass:integer}"                                                   
#>  [5] "#{colref:2},{colname:letters},{colclass:character}"                                                  
#>  [6] "#{colref:3},{colname:dates},{colclass:Date},{from:string}"                                           
#>  [7] "#{colref:4},{colname:posix},{colclass:POSIXct},{tz:EST},{tzoffset:-18000},{from:string}"             
#>  [8] "#{colref:5},{colname:itime},{colclass:ITime},{from:string}"                                          
#>  [9] "#{colref:6},{colname:logical},{colclass:logical},{from:long}"                                        
#> [10] "#{colref:7},{colname:factor},{colclass:factor},{levels:small,medium,large,extra-large},{from:string}"
#> [11] "#{colref:8},{colname:times},{colclass:times},{from:string}"                                          
#> [12] "integers,letters,dates,posix,itime,logical,factor,times"                                             
#> [13] "1,h,2107-12-31,1970-01-12T08:46:40Z,05:43:46,FALSE,extra-large,00:01:26"                             
#> [14] "2,u,2046-07-20,1970-01-12T09:03:20Z,23:05:47,TRUE,small,00:15:57"                                    
#> [15] "3,k,2082-05-19,1970-01-12T09:20:00Z,14:25:58,FALSE,extra-large,00:30:28"
```

The first line of the file contains some basic details about the file structure, below which is a series of lines specifying details of each column. This "header" section will be used by `read_rcsv` to import the data frame in a manner matching the file written out, without the need for special parameters on the read call, or additional manipulations after import.

Before importing the file, we can take a look at it in a few ways. `glimpse_rcsv` shows important details about the file, including notes and a `dplyr::glimpse`-alike view of the dataset, without loading the file into memory. (We go a little more into the `glimpse` function later.)

``` r
glimpse_rcsv( testfile )
#> 
#> 
#>  file:        READMEfiles/test.rcsv 
#>  total cols:  8 
#>  total rows:  100 
#> 
#>  Notes:       Here's an example note.
#>       And another one. 
#> 
#>  "integers" <int> 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21...
#>  "letters" <char> h,u,k,w,y,b,n,x,o,l,y,l,r,o,c,x,g,b,i,y,x...
#>  "dates" <date> 2107-12-31,2046-07-20,2082-05-19,2189-07-12,2081-01-24,2174-10-1...
#>  "posix" <posx> 1970-01-12 08:46:40,1970-01-12 09:03:20,1970-01-12 09:20:00,1970...
#>  "itime" <itim> 05:43:46,23:05:47,14:25:58,12:21:39,09:39:42,21:07:33,08:44:18,0...
#>  "logical" <logi> FALSE,TRUE,FALSE,FALSE,FALSE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,...
#>  "factor" <fct> extra-large,small,extra-large,large,medium,medium,large,small,me...
#>  "times" <time> 00:01:26,00:15:57,00:30:28,00:44:59,00:59:30,01:14:01,01:28:32,0...
```

`notes_rcsv` shows just the notes.

``` r
notes_rcsv( testfile )
#> Notes:   Here's an example note.
#>  And another one.
```

``` r
df.readrcsv <- read_rcsv( testfile )
#> Notes:  Here's an example note.
#>  And another one.
```

``` r
dplyr::glimpse( df.readrcsv, width = 80 )
#> Observations: 100
#> Variables: 8
#> $ integers <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,...
#> $ letters  <chr> "h", "u", "k", "w", "y", "b", "n", "x", "o", "l", "y", "l"...
#> $ dates    <date> 2107-12-31, 2046-07-20, 2082-05-19, 2189-07-12, 2081-01-2...
#> $ posix    <dttm> 1970-01-12 08:46:40, 1970-01-12 09:03:20, 1970-01-12 09:2...
#> $ itime    <S3: ITime> 05:43:46, 23:05:47, 14:25:58, 12:21:39, 09:39:42, 21...
#> $ logical  <lgl> FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, ...
#> $ factor   <fctr> extra-large, small, extra-large, large, medium, medium, l...
#> $ times    <S3: times> 00:01:26, 00:15:57, 00:30:28, 00:44:59, 00:59:30, 01...
```

All columns have been read in with identical column classes as the original test data frame.

Note that since the header section is designated by a \# at the beginning of each line. This means that any csv reader can still read the file, with "\#" passed as a comment character.

``` r
df.base <- read.csv( testfile, comment.char = "#" )
glimpse( df.base, width = 80 )
#> Observations: 100
#> Variables: 8
#> $ integers <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,...
#> $ letters  <fctr> h, u, k, w, y, b, n, x, o, l, y, l, r, o, c, x, g, b, i, ...
#> $ dates    <fctr> 2107-12-31, 2046-07-20, 2082-05-19, 2189-07-12, 2081-01-2...
#> $ posix    <fctr> 1970-01-12T08:46:40Z, 1970-01-12T09:03:20Z, 1970-01-12T09...
#> $ itime    <fctr> 05:43:46, 23:05:47, 14:25:58, 12:21:39, 09:39:42, 21:07:3...
#> $ logical  <lgl> FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, ...
#> $ factor   <fctr> extra-large, small, extra-large, large, medium, medium, l...
#> $ times    <fctr> 00:01:26, 00:15:57, 00:30:28, 00:44:59, 00:59:30, 01:14:0...
```

Using a regular reader however, will not necessarily import the columns correctly (note several incorrect import formats above). Even with the very good `readr` package, which does a great job, we won't always correctly attribute the original column classes, because there is ambiguity on the user's original intent.

``` r
df.readr <- readr::read_csv( testfile, comment = "#" )
glimpse( df.readr, width = 80 )
#> Observations: 100
#> Variables: 8
#> $ integers <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,...
#> $ letters  <chr> "h", "u", "k", "w", "y", "b", "n", "x", "o", "l", "y", "l"...
#> $ dates    <date> 2107-12-31, 2046-07-20, 2082-05-19, 2189-07-12, 2081-01-2...
#> $ posix    <dttm> 1970-01-12 08:46:40, 1970-01-12 09:03:20, 1970-01-12 09:2...
#> $ itime    <time> 05:43:46, 23:05:47, 14:25:58, 12:21:39, 09:39:42, 21:07:3...
#> $ logical  <lgl> FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, ...
#> $ factor   <chr> "extra-large", "small", "extra-large", "large", "medium", ...
#> $ times    <time> 00:01:26, 00:15:57, 00:30:28, 00:44:59, 00:59:30, 01:14:0...
```

Also try with `csvy`, a great package by Thomas J Leeper (<https://github.com/leeper/csvy>), looking to solve issues with csv use in a similar way to here.

``` r
testfile <- "READMEfiles/test.rcsv"
csvy::write_csvy( df, "READMEfiles/test.csvy" )
#> Warning in a$fields[[i]][2] <- class(x[[i]]): number of items to replace is
#> not a multiple of replacement length
#> Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
#> sep2, : appending column names to file
#> [1] "READMEfiles/test.csvy"
df.readcsvy <- csvy::read_csvy( "READMEfiles/test.csvy" )
dplyr::glimpse( df.readcsvy, width = 80 )
#> Observations: 100
#> Variables: 8
#> $ integers <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,...
#> $ letters  <chr> "h", "u", "k", "w", "y", "b", "n", "x", "o", "l", "y", "l"...
#> $ dates    <chr> "2107-12-31", "2046-07-20", "2082-05-19", "2189-07-12", "2...
#> $ posix    <chr> "1970-01-12 08:46:40", "1970-01-12 09:03:20", "1970-01-12 ...
#> $ itime    <chr> "05:43:46", "23:05:47", "14:25:58", "12:21:39", "09:39:42"...
#> $ logical  <lgl> FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, ...
#> $ factor   <chr> "extra-large", "small", "extra-large", "large", "medium", ...
#> $ times    <chr> "00:01:26", "00:15:57", "00:30:28", "00:44:59", "00:59:30"...
```

Note some issues are solved, but there is still significant work to do before the data is back to its original format. In particular, datetime and factor formats are returned as character columns, albeit with some helpful information stored as attributes.

``` r
sapply( df.readcsvy[,c(3,4,5,7,8)], attributes )
#> $dates
#> NULL
#> 
#> $posix
#> $posix$tzone
#> [1] "EST"
#> 
#> 
#> $itime
#> NULL
#> 
#> $factor
#> $factor$levels
#> [1] "small"       "medium"      "large"       "extra-large"
#> 
#> 
#> $times
#> $times$format
#> [1] "h:m:s"
```

Some of these issues will be easily fixed, like converting factors to strings, or vice-versa. Some are less simple though, for example timezones are generally\* not printed to csv files, meaning they are often read into memory with different timezone attributes from the original data frame. This can be difficult to notice if special care is not taken, and can have serious consequences. \*worth noting that `data.table::fwrite` does have a facility for this

``` r
cat( "Testing for timezone changes:\n",
     "from original data frame:\t", as.character( df$posix[1] ), attr( df$posix[1], "tzone" ), "\n",
     "using read_rcsv:\t\t\t", as.character( df.readrcsv$posix[1] ), attr( df.readrcsv$posix[1], "tzone" ), "\n",
     "using readr::read_csv:\t\t", as.character( df.readr$posix[1] ), attr( df.readr$posix[1], "tzone" ), "\n",
     "using base::read.csv:\t\t", as.character( df.base$posix[1] ), attr( df.base$posix[1], "tzone" ), "\n" )
#> Testing for timezone changes:
#>  from original data frame:    1970-01-12 08:46:40 EST 
#>  using read_rcsv:             1970-01-12 08:46:40 EST 
#>  using readr::read_csv:       1970-01-12 08:46:40 UTC 
#>  using base::read.csv:        1970-01-12T08:46:40Z
```

`factor` columns also raise an issue here, where they may be correctly read in as factor, but associated incorrect levels, which may have consequences on further data analysis:

``` r
cat( "Testing for factor level changes:\n",
     "from original data frame:\t", levels( df$factor ), "\n",
     "using read_rcsv:\t\t\t", levels( df.readrcsv$factor ), "\n",
     "using readr::read_csv:\t\t", levels( df.readr$factor ), "\n",
     "using csvy::read_csvy:\t\t", levels( df.readcsvy$factor ), "\n",
     "using base::read.csv:\t\t", levels( df.base$factor ) )
#> Testing for factor level changes:
#>  from original data frame:    small medium large extra-large 
#>  using read_rcsv:             small medium large extra-large 
#>  using readr::read_csv:       
#>  using csvy::read_csvy:       small medium large extra-large 
#>  using base::read.csv:        extra-large large medium small
```

`readr` defaults all columns without other conversion triggers to `character` class (hence there are no levels to display here). `csvy` correctly stores and retrieves the factor levels, but leaves the column as `character` class. `read.csv` defaults these columns to `factor` class, but automatically sorts levels in alphabetical order, which may not be appropriate, as is the case here. `rcsv` determines whether or not to convert a column to factor based on the data frame from which it was written, and stores then extracts the correct factor levels, including their order.

### using write\_rcsv with data conversion options

The `write_rcsv` function includes several options for "compressing" the csv output file by changing the way some columns are represented. We can control each conversion type individually with their respective parameters, or we can turn all of these options on with a single parameter, `strings.convert`.

``` r
rcsv::write_rcsv( df, testfile, strings.convert = TRUE )
#> Notes:  Here's an example note.
#>  And another one.
readLines( testfile, n = 15 )
#>  [1] "#{rcsvHeader},{headlines:11},{noteslines:2},{colreflines:8},{tablerows:100}"                                                      
#>  [2] "#{notes:Here's an example note.}"                                                                                                 
#>  [3] "#{notes:And another one.}"                                                                                                        
#>  [4] "#{colref:1},{colname:integers},{colclass:integer}"                                                                                
#>  [5] "#{colref:2},{colname:letters},{colclass:character},{levels:a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z},{from:factorints}"
#>  [6] "#{colref:3},{colname:dates},{colclass:Date},{from:integer}"                                                                       
#>  [7] "#{colref:4},{colname:posix},{colclass:POSIXct},{tz:EST},{tzoffset:-18000},{from:integer}"                                         
#>  [8] "#{colref:5},{colname:itime},{colclass:ITime},{from:integer}"                                                                      
#>  [9] "#{colref:6},{colname:logical},{colclass:logical},{from:integer}"                                                                  
#> [10] "#{colref:7},{colname:factor},{colclass:factor},{levels:small,medium,large,extra-large},{from:integer}"                            
#> [11] "#{colref:8},{colname:times},{colclass:times},{from:numeric}"                                                                      
#> [12] "integers,letters,dates,posix,itime,logical,factor,times"                                                                          
#> [13] "1,8,50402,1000000,20626,0,4,0.001"                                                                                                
#> [14] "2,21,27959,1001000,83147,1,1,0.0110808080808081"                                                                                  
#> [15] "3,11,41046,1002000,51958,0,4,0.0211616161616162"
```

The data itself here looks significantly different from the regular csv. character strings, factors, dates, times, and logical objects are all being represented in integer or numeric form, to be converted back to their respective classes on import using the information stored in the header, without any extra parameters needing to be passed to the import call:

``` r
df.readrcsv.convert <- read_rcsv( testfile )
#> Notes:  Here's an example note.
#>  And another one.
glimpse( df.readrcsv.convert )
#> Observations: 100
#> Variables: 8
#> $ integers <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16...
#> $ letters  <chr> "h", "u", "k", "w", "y", "b", "n", "x", "o", "l", "y"...
#> $ dates    <date> 2107-12-31, 2046-07-20, 2082-05-19, 2189-07-12, 2081...
#> $ posix    <dttm> 1970-01-12 08:46:40, 1970-01-12 09:03:20, 1970-01-12...
#> $ itime    <S3: ITime> 05:43:46, 23:05:47, 14:25:58, 12:21:39, 09:39:4...
#> $ logical  <lgl> FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, T...
#> $ factor   <fctr> extra-large, small, extra-large, large, medium, medi...
#> $ times    <S3: times> 00:01:26, 00:15:57, 00:30:28, 00:44:59, 00:59:3...
```

File writing.
-------------

### Why use conversions?

By converting columns in this way, we may save disk space\*, as well as speed up reading and writing, while retaining the original data, and maintaining meaningful diffs. It is certainly less of a "general" data storage method (although the details needed to convert back to the original data types is mostly human-readable in the header, but I digress...) than without these conversions, but it may be useful in some situations.

To see the file size and speed advantages, we'll create a more meaningful (bigger) dataset, and write it to files with several different methods.

-   Character columns with highly repeated string fields will benefit greatly, whereas those with completely unique string fields will not. `Date`, `ITime`, and `IDate` formats are all more efficiently stored as integers than character strings, and will generally convert to their proper classes faster from integers than from character strings. `POSIXct` is likewise more efficiently converted from numeric, and this also makes storage of greater precision than 1s simpler and more efficient. Similarly, `times` format values stored as numeric enables greater than 1s precision values to be stored and retrieved, however in some cases may increase storage size (where the decimal values convert to longer strings than the formatted time value).

### File write speeds

We test the speed of file writing between a few of the methods available to an R user.

``` r
n <- 1E5
df <- testDF( n )
write.times <- microbenchmark::microbenchmark(
    base_write = write.csv( df, "READMEfiles/base_write.csv" ),
    csvy_write = csvy::write_csvy( df, "READMEfiles/csvy_write.csvy" ),
    readr_write = readr::write_csv( df, "READMEfiles/readr_write.csv" ),
    dt_fwrite = data.table::fwrite( df, "READMEfiles/dt_fwrite.csv" ),
    rcsv_noconvert = rcsv::write_rcsv( df, "READMEfiles/rcsv_noconvert.rcsv" ),
    rcsv_convert = rcsv::write_rcsv( df, "READMEfiles/rcsv_convert.rcsv", strings.convert = TRUE ),
    rds_default = saveRDS( df, "READMEfiles/rds_default.rds" ),
    fst = fst::write.fst( df, "READMEfiles/fst.fst" ),
    feather = feather::write_feather( df, "READMEfiles/feather.feather" ),
    times = 12
)
#> Warning in a$fields[[i]][2] <- class(x[[i]]): number of items to replace is
#> not a multiple of replacement length
#> Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
#> sep2, : appending column names to file
#> Warning in a$fields[[i]][2] <- class(x[[i]]): number of items to replace is
#> not a multiple of replacement length
#> Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
#> sep2, : appending column names to file
#> Warning in a$fields[[i]][2] <- class(x[[i]]): number of items to replace is
#> not a multiple of replacement length
#> Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
#> sep2, : appending column names to file
#> Warning in a$fields[[i]][2] <- class(x[[i]]): number of items to replace is
#> not a multiple of replacement length
#> Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
#> sep2, : appending column names to file
#> Warning in a$fields[[i]][2] <- class(x[[i]]): number of items to replace is
#> not a multiple of replacement length
#> Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
#> sep2, : appending column names to file
#> Warning in a$fields[[i]][2] <- class(x[[i]]): number of items to replace is
#> not a multiple of replacement length
#> Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
#> sep2, : appending column names to file
#> Warning in a$fields[[i]][2] <- class(x[[i]]): number of items to replace is
#> not a multiple of replacement length
#> Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
#> sep2, : appending column names to file
#> Warning in a$fields[[i]][2] <- class(x[[i]]): number of items to replace is
#> not a multiple of replacement length
#> Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
#> sep2, : appending column names to file
#> Warning in a$fields[[i]][2] <- class(x[[i]]): number of items to replace is
#> not a multiple of replacement length
#> Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
#> sep2, : appending column names to file
#> Warning in a$fields[[i]][2] <- class(x[[i]]): number of items to replace is
#> not a multiple of replacement length
#> Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
#> sep2, : appending column names to file
#> Warning in a$fields[[i]][2] <- class(x[[i]]): number of items to replace is
#> not a multiple of replacement length
#> Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
#> sep2, : appending column names to file
#> Warning in a$fields[[i]][2] <- class(x[[i]]): number of items to replace is
#> not a multiple of replacement length
#> Warning in write.table(file = file, x = x, append = TRUE, sep = sep, dec =
#> sep2, : appending column names to file
write.times
#> Unit: milliseconds
#>            expr         min          lq       mean     median         uq
#>      base_write 1865.122737 1960.132106 2074.49549 2069.99542 2147.87738
#>      csvy_write 1924.328024 2026.509486 2078.96079 2083.87210 2135.93451
#>     readr_write 1779.642001 1876.205240 1917.23784 1915.24497 1947.86314
#>       dt_fwrite   29.536957   33.190015   34.29838   34.28722   35.27978
#>  rcsv_noconvert  630.414506  649.103992  682.35327  676.52768  701.22461
#>    rcsv_convert   40.031094   41.885119   62.43568   56.67724   68.95914
#>     rds_default  433.450496  438.296296  441.60673  443.68539  445.02834
#>             fst    9.622395    9.825881   23.15253   10.70773   15.92769
#>         feather    9.445226   10.193075   16.59175   11.10621   20.09081
#>         max neval
#>  2474.21459    12
#>  2222.01192    12
#>  2141.48119    12
#>    38.38364    12
#>   763.02340    12
#>   153.51439    12
#>   446.52835    12
#>   133.82114    12
#>    40.51175    12
```

`write_rcsv` is built around the fantastic `data.table::fwrite` function, making it much faster than both `base::write.csv` and `readr::write_csv`. It even maintains relatively good performance compared with `data.table::fwrite`, but is slowed a little by the conversion processes and header writing steps.

``` r
ggplot( write.times,
        mapping = aes( expr, time/1E9, colour = expr ) ) +
    geom_violin( show.legend = FALSE ) +
    geom_jitter( size = 1, alpha = 0.4, width = 0.5, show.legend = FALSE ) +
    ylab( "write time (s)" ) + xlab( "" ) +
    ylim( c( 0, NA ) ) +
    labs( title = "File write times.",
          subtitle = sprintf( "%s row by %s column data frame.", n, ncol( df ) ) )
```

![](READMEfigs/unnamed-chunk-21-1.png)

The speed differences between `dt.fwrite`, `rcsv.noconvert`, and `rcsv.convert` seen here are the result of additional processing in the `write_rcsv` function (slowing it down), and the advantage of writing fewer characters to file (speeding it up where `strings.convert` == TRUE). Without string conversions, `rcsv` generally writes with comparable speed to `saveRDS`, while turning the string conversions on can make it significantly faster.

### File sizes

``` r
files <- list.files( path = "READMEfiles/", full.names = TRUE )
files <- files[ !grepl( "test.rcsv", files ) ]
sizes <- file.info( files )$size

ggplot( data = data.frame( files = gsub( ".*\\/|\\..*", "", files ), size = sizes ),
        mapping = aes( files, sizes/1E6, fill = files ) ) +
    geom_col( show.legend = FALSE ) +
    labs( title = "File sizes on disk." ) +
    xlab( "" ) + ylab( "File size (MB)" ) +
    theme(axis.text.x = element_text(size = 10, angle = 20, hjust = 1)) +
    geom_text( aes( label = paste( signif( sizes/1E6, 2 ), "MB" ), y = 0.7 * sizes/1E6 ),
               position = position_dodge(0.9),
               vjust = 0
    )
```

![](READMEfigs/unnamed-chunk-22-1.png)

Note most csv writers create files of similar sizes, but the `rcsv` format with string conversions can (in some circumstances) result in significant file size reductions. We do not have the same file size benefit of the compressed (as per default settings) `rds` format, so if file size is of paramount importance, it may be worth sticking with the rds format, or including an extra file compression step to your workflow; that is not the primary concern here though.

### File read times

``` r
read.times <- microbenchmark::microbenchmark(
    base_read = { df.base <- read.csv( "READMEfiles/base_write.csv" ) },
    csvy_read = { df.csvy <- csvy::read_csvy( "READMEfiles/csvy_write.csvy" ) },
    readr_read = { df.readr <- readr::read_csv( "READMEfiles/readr_write.csv" ) },
    dt_fread = { df.fread <- data.table::fread( "READMEfiles/dt_fwrite.csv" ) },
    rcsv_noconvert = { df.noconvert <- rcsv::read_rcsv( "READMEfiles/rcsv_noconvert.rcsv" ) },
    rcsv_convert = { df.convert <- rcsv::read_rcsv( "READMEfiles/rcsv_convert.rcsv" ) },
    rds_default = { df.rds <- readRDS( "READMEfiles/rds_default.rds" ) },
    fst = { df.fst <- fst::read.fst( "READMEfiles/fst.fst" ) },
    feather = { df.feather <- feather::read_feather( "READMEfiles/feather.feather" ) },
    times = 12
)
read.times
#> Unit: milliseconds
#>            expr         min          lq       mean      median          uq
#>       base_read 1842.221655 1872.251161 1933.88055 1915.581091 1989.957515
#>       csvy_read 1195.990764 1208.052876 1308.25454 1272.742672 1410.618937
#>      readr_read  156.267053  163.746084  196.62871  168.848405  207.810022
#>        dt_fread  104.207240  110.312232  122.93030  114.652682  137.284966
#>  rcsv_noconvert  219.891251  224.664609  259.44735  234.687201  273.324076
#>    rcsv_convert   95.920611   97.407859  124.18664  101.221127  123.217694
#>     rds_default   44.853619   47.423863   49.92746   49.816311   52.541821
#>             fst    5.607810    6.883768   11.78424    7.517616    9.519244
#>         feather    5.295504    6.381062   23.00218    7.047912   17.199560
#>         max neval
#>  2081.06491    12
#>  1443.47300    12
#>   309.22069    12
#>   163.16272    12
#>   450.65072    12
#>   281.89342    12
#>    56.08788    12
#>    38.16745    12
#>   157.19320    12
```

``` r
ggplot( data = read.times,
        mapping = aes( expr, time/1E9, colour = expr ) ) +
    geom_violin( show.legend = FALSE ) +
    geom_jitter( size = 1, alpha = 0.4, width = 0.5, show.legend = FALSE ) +
    ylab( "read time (s)" ) + xlab( "" ) +
    ylim( c( 0, NA ) ) +
    labs( title = "File read times.",
          subtitle = sprintf( "%s row by %s column data frame.", n, ncol( df ) ) )
```

![](READMEfigs/unnamed-chunk-24-1.png)

We can see here that when reading in data, the speed of `rcsv` is excellent if conversions are used, and very competitive even without conversions. Note the time spent here is on applying conversions to the data on import. These conversions would usually need to be performed manually after import, meaning that a more appropriate comparison between both forms of `read_rcsv` and other read methods may be to include those conversion steps

``` r
read.times.with.manipulations <- microbenchmark::microbenchmark(
    readr_read = {
        df.readr.manip <- readr::read_csv( "READMEfiles/readr_write.csv",
                                           col_types = cols(
                                               col_integer(),
                                               col_character(),
                                               col_date(),
                                               col_datetime(),
                                               col_time(),
                                               col_logical(),
                                               col_factor(
                                                   levels = c( "small", "medium", "large", "extra-large" )
                                               ),
                                               col_time()
                                           ) ) %>%
            mutate( posix = lubridate::with_tz( posix, tzone = "EST" ),
                    itime = as.ITime( itime ),
                    times = chron::times( times ) )
        },
    dt_fread = { 
        df.fread.manip <- data.table::fread( "READMEfiles/dt_fwrite.csv" )
        df.fread.manip[ , dates := as.Date( dates )
                     ][ , posix := fasttime::fastPOSIXct( posix, tz = "EST" )
                     ][ , itime := as.ITime( itime )
                     ][ , factor := factor( factor, levels = c( "small", "medium", "large", "extra-large" ) )
                     ][ , times := chron::times( times ) ] },
    rcsv_noconvert = { df.noconvert <- rcsv::read_rcsv( "READMEfiles/rcsv_noconvert.rcsv" ) },
    rcsv_convert = { df.convert <- rcsv::read_rcsv( "READMEfiles/rcsv_convert.rcsv" ) },
    csvy = {
        df.csvy <- csvy::read_csvy( "READMEfiles/csvy_write.csvy" )
        df.csvy$dates <- as.Date( df.csvy$dates )
        df.csvy$posix <- as.POSIXct( df.csvy$posix, tz = attr( df.csvy$posix, "tzone" ) )
        df.csvy$itime <- as.ITime( df.csvy$itime )
        df.csvy$factor <- factor( df.csvy$factor, levels = attr( df.csvy$factor, "levels" ) )
        df.csvy$times <- chron::times( df.csvy$times )
    },
    times = 12
)
read.times.with.manipulations
#> Unit: milliseconds
#>            expr        min         lq      mean    median        uq
#>      readr_read  631.68679  648.37885  691.8882  655.2630  720.3588
#>        dt_fread 2506.27575 2516.52530 2592.8815 2566.1288 2649.4746
#>  rcsv_noconvert  212.10188  227.40729  237.0061  236.7808  244.0867
#>    rcsv_convert   92.01534   94.49969  107.8380  109.2338  119.0644
#>            csvy 6332.20657 6466.35811 6624.4969 6539.6950 6769.6372
#>        max neval
#>   866.6443    12
#>  2804.7160    12
#>   257.9417    12
#>   125.3447    12
#>  7078.1915    12
```

``` r
ggplot( setDT( read.times.with.manipulations )[ grepl( "^base|^readr|^rcsv|^dt|^csvy", expr ) ],
        mapping = aes( expr, time/1E9, colour = expr ) ) +
    geom_violin( show.legend = FALSE ) +
    geom_jitter( size = 1, alpha = 0.4, width = 0.5, show.legend = FALSE ) +
    ylab( "read time (s)" ) + xlab( "" ) +
    ylim( c( 0, NA ) ) +
    labs( title = "File read times, with column manipulations where necessary.",
          subtitle = sprintf( "%s row by %s column data frame.", n, ncol( df ) ) )
```

![](READMEfigs/unnamed-chunk-26-1.png)

So, assuming you'll be performing the necessary data conversions on import, `fread` is actually significantly slower than `rcsv`. In the case of `rcsv_convert`, this is due to the fact that converting from numeric variables is often faster than from character. In the case of `rcsv_noconvert`, it is largely due to the use of several speed optimisations, including the use of c++ as well as the `fasttime` package in converting datetime variables to improve speeds over `as.Date`, `as.POSIXct`, `chron::times`, `data.table::as.ITime`, `data.table::as.IDate` functions.

Data integrity
--------------

### Testing that the data has been read in correctly.

To test for correct data read, we look at each column of each imported data frame, and compare it to the matching column in the original data frame. In this way, we see if the data has remained consistent through the write/read process.

``` r
tests <- lapply( X = list( df.convert = df.convert,
                           df.noconvert = df.noconvert,
                           df.fread.manip = df.fread.manip,
                           df.readr.manip = df.readr.manip,
                           df.csvy = df.csvy ),
                 FUN = function(x) {
                     sapply( seq_along( df ),
                             function(i) all.equal( df[[i]], x[[i]] )
                     )
                 }
) %>%
    lapply( function(x) paste( x, collapse = ", " ) )
print( tests )
#> $df.convert
#> [1] "TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE"
#> 
#> $df.noconvert
#> [1] "TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, Mean relative difference: 5.787027e-06"
#> 
#> $df.fread.manip
#> [1] "TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE"
#> 
#> $df.readr.manip
#> [1] "TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, Mean relative difference: 5.787027e-06"
#> 
#> $df.csvy
#> [1] "TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, Mean relative difference: 5.787027e-06"
```

It's clear here that imports using regular csv readers will need some work to bring the data back to the way it should be. This manipulation needs to be repeated every time a dataset is read into memory, which can be quite prohibitive to a smooth workflow. With `rcsv`, the data is read back into R in the same form as before it was written out\*, with no additional time or effort on the part of the user.

-   the one exception here is where `times` values have been stored without numeric conversion. The slight discrepancy in the values retrieved is due to the conversion of greater than 1s precision time values to formatted strings ("h:m:s"), which does not allow for the storage of such high precision. Turning conversion on in the `write_rcsv` call solves this by storing as numeric, and therefore retaining the precision of the original data. `fwrite` defaults to writing `times` values as numeric, but we overwrite this where necessary to create a more portable csv file (times written out as "h:m:s" character strings).

Additional features
-------------------

### Notes, an added detail to your datasets

Sometimes it's important to include a few brief notes with your dataset. Maybe the specs for a piece of equipment used to collect the data, or maybe something that a user of the dataset should be aware of when working with it. The `rcsv` format has this facility built in. You can add a note to your data frame, which is stored as an attribute named `notes`.

``` r
df <- testDF( 100 )
notes_add( df, "All the data here was collected with a model X super-duper measuring device" )
#> Notes:   All the data here was collected with a model X super-duper measuring device
```

We can replace any existing notes with `notes_replace`, or we can add another note with `notes_add`

``` r
notes_add( df, "The equipment was calibrated using ISO 9000" )
#> Notes:   All the data here was collected with a model X super-duper measuring device
#>  The equipment was calibrated using ISO 9000
```

Each time a note is added, the full set of notes are printed to the console. This console print will also happen whenever the data is written to file...

``` r
write_rcsv( df, testfile )
#> Notes:  All the data here was collected with a model X super-duper measuring device
#>  The equipment was calibrated using ISO 9000
```

And whenever it is read from file.

``` r
df <- read_rcsv( testfile )
#> Notes:  All the data here was collected with a model X super-duper measuring device
#>  The equipment was calibrated using ISO 9000
```

These notes are stored in the file header in a human-readable way, meaning that they can be accessed even without the `rcsv` package.

``` r
readLines( testfile, 3 )
#> [1] "#{rcsvHeader},{headlines:11},{noteslines:2},{colreflines:8},{tablerows:100}"         
#> [2] "#{notes:All the data here was collected with a model X super-duper measuring device}"
#> [3] "#{notes:The equipment was calibrated using ISO 9000}"
```

### Helper functions

The `rcsv` package also includes several helper functions to work with rcsv files, without loading the entire dataset into memory. These functions are therefore very fast ways to access details on even very large data files.

### glimpse\_rcsv

`glimpse_rcsv` displays a `dplyr::glimpse`-like view of the data in the console (and silently returns a list of these details), without loading the entire dataset into memory. This is a very efficient way of viewing key details about a dataset without importing it.

``` r
details <- glimpse_rcsv( testfile )
#> 
#> 
#>  file:        READMEfiles/test.rcsv 
#>  total cols:  8 
#>  total rows:  100 
#> 
#>  Notes:       All the data here was collected with a model X super-duper measuring device
#>       The equipment was calibrated using ISO 9000 
#> 
#>  "integers" <int> 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21...
#>  "letters" <char> c,o,r,a,g,o,o,k,w,q,x,i,q,n,z,s,d,j,x,a,v...
#>  "dates" <date> 2108-08-01,2053-03-17,2129-10-31,2018-08-27,2146-04-15,1985-10-1...
#>  "posix" <posx> 1970-01-12 08:46:40,1970-01-12 09:03:20,1970-01-12 09:20:00,1970...
#>  "itime" <itim> 16:27:13,12:46:35,00:45:31,03:43:23,14:44:26,18:49:02,17:28:38,0...
#>  "logical" <logi> TRUE,TRUE,FALSE,FALSE,TRUE,FALSE,FALSE,TRUE,FALSE,TRUE,FALSE,TRU...
#>  "factor" <fct> small,large,extra-large,medium,extra-large,small,small,large,med...
#>  "times" <time> 00:01:26,00:15:57,00:30:28,00:44:59,00:59:30,01:14:01,01:28:32,0...
```

Useful details are returned as a list, meaning they can be referenced using `$` or `[[`

``` r
print( details )
#> $dim
#> rows cols 
#>  100    8 
#> 
#> $names
#> [1] "integers" "letters"  "dates"    "posix"    "itime"    "logical" 
#> [7] "factor"   "times"   
#> 
#> $classes
#>    integers     letters       dates       posix       itime     logical 
#>   "integer" "character"      "Date"   "POSIXct"     "ITime"   "logical" 
#>      factor       times 
#>    "factor"     "times" 
#> 
#> $notes
#> [1] "All the data here was collected with a model X super-duper measuring device"
#> [2] "The equipment was calibrated using ISO 9000"
```

``` r
details$dim
#> rows cols 
#>  100    8
```

### notes\_rcsv

`notes_rcsv` returns only the notes associated with a data file, without loading the dataset.

``` r
notes_rcsv( testfile )
#> Notes:   All the data here was collected with a model X super-duper measuring device
#>  The equipment was calibrated using ISO 9000
```

This will also accept a data frame with the "notes" attribute. ie: after being read into R

``` r
notes_rcsv( df )
#> Notes:   All the data here was collected with a model X super-duper measuring device
#>  The equipment was calibrated using ISO 9000
```
