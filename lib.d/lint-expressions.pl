#!/usr/bin/perl -n

if (/^\s*%\w+(?=[^\w%])/) {  # catch "%IF" and similar single-percent typos
    print "suspicious expression at $ARGV line $.: $_";
    next;
}

if (/^\s*((%%\w+)|([^%\s])).*%%/) { # catch "%%VAR%%" and other stupidity
    print "suspicious variable at $ARGV line $.: $_";
    # fallthru
}
