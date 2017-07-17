#include <Rcpp.h>
#include <stdlib.h>
#include <stdio.h>
using namespace Rcpp;

//' @title toTimeDay
//' @description convert character times to fraction of the day
//'
//'
//' @param x character vector, input times
//'
//' @keywords time
//' @useDynLib rcsv
//' @export
//'
// [[Rcpp::export]]

NumericVector toTimeDay(CharacterVector x) {
    int hh, mm;
    float ss;
    double val;
    int len = x.size();
    NumericVector times( len );

    for( int i = 0; i < len; i++ ) {
        sscanf( x[i], "%d:%d:%f", &hh, &mm, &ss );
        val = hh*3600 + mm*60 + ss;
        times[i] = val / 86400;
    }
    return times;
}
