#!/bin/sh
# eotk (c) 2017 Alec Muffett

#OPENSSL=openssl # try to use at least v1.0.2
OPENSSL=/usr/local/opt/openssl/bin/openssl

for certfile in "$@" ; do
    $OPENSSL x509 -in $certfile -noout -text
done

exit 0
