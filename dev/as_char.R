#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]

CharacterVector as_char(NumericVector x) {
    int len = x.size();
    double time;
    int h, m, s;

    if( max( x ) < 1 ) {
        for( int i = 0; i < len; i++ ) {
            x[i] = x[i] * 86400;
        }
    }

    output = CharacterVector( len );

    for( int i = 0;, i < len; i++ ) {
        time = x[i];
        s = time % 60;
        m = ( time - s ) % 3600;
        h = ( time - s - m ) / 3600;
        output[i] << h << ":" << m << ":" << s;
    }

  return output;
}

/*** R
as_char( as.numeric( chron::times( "10:00:00", "01:00:01" ) ) )
*/
