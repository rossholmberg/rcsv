#include <Rcpp.h>

using namespace Rcpp;

// [[Rcpp::export]]

std::vector<std::string> asChar(NumericVector x) {
    int len = x.size();
    int time;
    int h, m, s;
    std::string hs, ms, ss;

    std::vector<std::string> chars( 61 );
    chars[0] = "00";
    chars[1] = "01";
    chars[2] = "02";
    chars[3] = "03";
    chars[4] = "04";
    chars[5] = "05";
    chars[6] = "06";
    chars[7] = "07";
    chars[8] = "08";
    chars[9] = "09";
    chars[10] = "10";
    chars[11] = "11";
    chars[12] = "12";
    chars[13] = "13";
    chars[14] = "14";
    chars[15] = "15";
    chars[16] = "16";
    chars[17] = "17";
    chars[18] = "18";
    chars[19] = "19";
    chars[20] = "20";
    chars[21] = "21";
    chars[22] = "22";
    chars[23] = "23";
    chars[24] = "24";
    chars[25] = "25";
    chars[26] = "26";
    chars[27] = "27";
    chars[28] = "28";
    chars[29] = "29";
    chars[30] = "30";
    chars[31] = "31";
    chars[32] = "32";
    chars[33] = "33";
    chars[34] = "34";
    chars[35] = "35";
    chars[36] = "36";
    chars[37] = "37";
    chars[38] = "38";
    chars[39] = "39";
    chars[40] = "40";
    chars[41] = "41";
    chars[42] = "42";
    chars[43] = "43";
    chars[44] = "44";
    chars[45] = "45";
    chars[46] = "46";
    chars[47] = "47";
    chars[48] = "48";
    chars[49] = "49";
    chars[50] = "50";
    chars[51] = "51";
    chars[52] = "52";
    chars[53] = "53";
    chars[54] = "54";
    chars[55] = "55";
    chars[56] = "56";
    chars[57] = "57";
    chars[58] = "58";
    chars[59] = "59";
    chars[60] = "60";


    std::vector<std::string> output( len );

    // convert `times` numbers to numeric if necessary
    // if( max( x ) <= 1 ) {
    //     for( int i = 0; i < len; i++ ) {
    //         x[i] = x[i] * 86400;
    //     }
    // }

    for( int i = 0; i < len; i++ ) {

        time = x[i];

        // get the sec, min, and hrs components, and convert to string

        s = time % 60;
        ss = chars[s];
        m = ( ( time - s ) / 60 ) % 60;
        ms = chars[m];
        h = ( time - s - m*60 ) / 3600;
        hs = chars[h];

        // concatenate the output string
        output[i] = hs + ":" + ms + ":" + ss;
    }

  return output;
}

/*** R
asChar( data.table::as.ITime( c( "10:00:00", "01:15:00" ) ) )
*/
