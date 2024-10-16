#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

SV* _scalar_type(SV* argument) {
    SV* rval;
    static char num_as_str[100]; /* potential buffer overflow on 256-bit machines :-) */

    /* NB that we can't rely on SvIOK/SvNOK/SvPOK alone to see what the SV was
     * originally. As perlguts.pod says: "Be aware that retrieving the numeric
     * value of an SV can set IOK or NOK on that SV, even when the SV started
     * as a string. Prior to Perl 5.36.0 retrieving the string value of an
     * integer could set POK, but this can no longer occur. From 5.36.0 this
     * can be used to distinguish the original representation of an SV" (ie to
     * tell whether it was originally a string or a number).
     *
     * We are not just targeting 5.36 and above.
    */
    if(SvIOK(argument)) {
        if(SvPOK(argument)) {
            /* int is also a string, better see if it's not int-ified 007 */
            sprintf(
                num_as_str,
                (SvIsUV(argument) ? "%" UVuf        : "%" IVdf),
                (SvIsUV(argument) ? SvUVX(argument) : SvIVX(argument))
            );
            rval = (
                (strcmp(SvPVX(argument), num_as_str)) == 0
                    ? newSVpv("INTEGER", 7)
                    : newSVpv("SCALAR",  6)
            );
        } else {
            rval = newSVpv("INTEGER", 7);
        }
    } else if(SvNOK(argument)) {
        if(SvPOK(argument)) {
            /* float is also a string, better see if it's not float-ified 007.5 */
            sprintf(num_as_str, "%" NVgf, SvNVX(argument));
            rval = (
                (strcmp(SvPVX(argument), num_as_str)) == 0
                    ? newSVpv("NUMBER", 6)
                    : newSVpv("SCALAR", 6)
            );
        } else {
            rval = newSVpv("NUMBER", 6);
        }
    } else {
        rval = newSVpv("SCALAR",  6);
    }

    return rval;
}


MODULE = Scalar::Type  PACKAGE = Scalar::Type  

PROTOTYPES: DISABLE

SV *
_scalar_type (argument)
	SV *	argument

