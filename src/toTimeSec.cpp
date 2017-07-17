#include <Rcpp.h>
#include <stdlib.h>
#include <stdio.h>
using namespace Rcpp;

//' @title toTimeSec
//' @description convert character times to integer seconds since midnight
//'
//'
//' @param x character vector, input times
//'
//' @keywords time
//' @useDynLib rcsv
//' @export
//'
// [[Rcpp::export]]

NumericVector toTimeSec(CharacterVector x) {
    int hh, mm;
    float ss;
    double val;
    int len = x.size();
    NumericVector times( len );

    for( int i = 0; i < len; i++ ) {
        sscanf( x[i], "%d:%d:%f", &hh, &mm, &ss );
        val = hh*3600 + mm*60 + ss;
        times[i] = val;
    }
    return times;
}
