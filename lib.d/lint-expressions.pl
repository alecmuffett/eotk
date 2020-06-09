#!/bin/sh
exec perl -nx $0 "$@";
#!perl -n
# eotk (c) 2017-2020 Alec Muffett

if (/^\s*%\w+(?=[^\w%])/) {  # catch "%IF" and similar single-percent typos
    print "suspicious expression at $ARGV line $.: $_";
    next;
}

if (/^\s*((%%\w+)|([^%\s])).*%%/) { # catch "%%VAR%%" and other stupidity
    print "suspicious maybe-variable at $ARGV line $.: $_";
    # fallthru
}

if (s/^\s*%%(\w+)//) {
    print "suspicious maybe-directive '$1' at $ARGV line $.: $_"
        unless ($1 =~ /^(IF|CSV|RANGE|ELSE|BEGIN|END(|IF|CSV|RANGE)|SPLICE|INCLUDE)$/o)
}
