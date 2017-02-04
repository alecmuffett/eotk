#!/bin/sh
# eotk (c) 2017 Alec Muffett

BREW_OPENSSL=/usr/local/opt/openssl/bin/openssl
if [ -f $BREW_OPENSSL ] ; then
    OPENSSL=$BREW_OPENSSL
    OPENSSL_CONFIG=/usr/local/etc/openssl/openssl.cnf
else
    OPENSSL=openssl
    OPENSSL_CONFIG=/etc/ssl/openssl.cnf
fi

for certfile in "$@" ; do
    $OPENSSL x509 -in $certfile -noout -text
done

exit 0
