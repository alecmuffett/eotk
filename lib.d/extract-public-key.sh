#!/bin/sh
# eotk (c) 2017 Alec Muffett

BREW_OPENSSL=/usr/local/opt/openssl/bin/openssl

if [ -f $BREW_OPENSSL ] ; then
    OPENSSL=$BREW_OPENSSL
else
    OPENSSL=openssl
fi

for privkey in "$@" ; do
    case "$privkey" in
        *.key) ;;
        *) echo error: file argument $privkey lacks a .key suffix 1>&2 ; exit 1 ;;
    esac
    prefix=`basename "$privkey" .key`
    pubkey="$prefix".pub
    echo reading $privkey...
    $OPENSSL rsa -in "$privkey" -pubout -out "$pubkey" || exit 1
done

exit 0
