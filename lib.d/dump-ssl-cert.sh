#!/bin/sh
# eotk (c) 2017 Alec Muffett

BREW_OPENSSL=/usr/local/opt/openssl/bin/openssl

if [ -f $BREW_OPENSSL ] ; then
    OPENSSL=$BREW_OPENSSL
else
    OPENSSL=openssl
fi

for certfile in "$@" ; do
    $OPENSSL x509 -in $certfile -noout -text
done

exit 0
