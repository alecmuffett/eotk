#!/bin/sh
# eotk (c) 2019 Alec Muffett

if [ "x$1" = "x" ] ; then
    echo "usage: $0 foo.com [sub.foo.com ...] (wildcards are added by this script)" 1>&2
    exit 1
fi

# 2019: reorganised argument parsing to accomodate `mkcert`

PRIMARY="$1" # first argument = primary domain

pemfile="$PRIMARY.pem"
csrfile="$PRIMARY.csr"
certfile="$PRIMARY.cert"

this=`basename $0`

# abort on any pre-existing PEM clash, figure it out later
for existing in $pemfile $csrfile $certfile ; do
    if [ -s $existing ] ; then
        echo $this: $existing already exists, exiting... 1>&2
        exit 1
    fi
done

tmp_suffix="$$.tmp"
dns="dns_${tmp_suffix}"

for tld in "$@" ; do
    echo "$tld" # for every foo.com
    echo "*.$tld" # add a wildcard: *.foo.com
done > $dns # is used in mkcert, or lower down

if [ x$SSL_MKCERT = x1 ] ; then # placeholder punting to mkcert
    echo doing: mkcert -cert-file $certfile -key-file $pemfile `cat $dns` 1>&2
    mkcert -cert-file $certfile -key-file $pemfile `cat $dns` || exit 1
    rm $dns
    exit 0
fi

# there is a *lot* of bad advice on the web about how to do this -
# which is understandable because some of it is geared at making a
# local CA first, other bits assume you are happy to permanently hack
# your config files, etc. this method is inspired by:
# https://dzone.com/articles/openssl-certificate-with-subjectaltname-one-liner
# ...plus a lot of wading through bad advice

# further, the above generates a RSA4096 with SHA1, which is both huge
# and pants, so we'll try self-signable ECDSA from the following page:
# https://security.stackexchange.com/questions/44251/openssl-generate-different-types-of-self-signed-certificate

# that still leaves it as "ANSI X9.62 ECDSA Signature with SHA1",
# though the transport is decently encrypted; let's use this page:
# https://msol.io/blog/tech/create-a-self-signed-ecc-certificate/
# ...and actually use the SHA256 signature.

# ...and it turns out the problem is OSX ships with 0.9.8 in the $PATH

DAYS=30 # cert lifetime

BREW_OPENSSL=/usr/local/opt/openssl/bin/openssl

if [ -f $BREW_OPENSSL ] ; then
    OPENSSL=$BREW_OPENSSL
    OPENSSL_CONFIG=/usr/local/etc/openssl/openssl.cnf
else
    OPENSSL=openssl
    OPENSSL_CONFIG=/etc/ssl/openssl.cnf
fi

dn_c="AQ" # CountryName: Antarctica
dn_st="The Internet" # StateOrProvinceName
dn_l="Onion Space" # LocalityName
dn_o="The SSL Onion Space" # OrganizationName
dn_ou="Self Signed Certificates" # OrganizationalUnitName
SUBJECT="/C=${dn_c}/ST=${dn_st}/L=${dn_l}/O=${dn_o}/OU=${dn_ou}/CN=${PRIMARY}"

subjectaltname=`awk '{printf "DNS." NR ":" $1 ","}' < $dns | sed -e 's/,$//'`

rm $dns

ssl_config="openssl_${tmp_suffix}"

(
    cat $OPENSSL_CONFIG
    echo ""
    echo "[SAN]"
    echo "subjectAltName='$subjectaltname'"
) > $ssl_config

$OPENSSL ecparam \
        -genkey \
        -out $pemfile \
        -name prime256v1

$OPENSSL req \
        -sha256 \
        -days $DAYS \
        -nodes \
        -x509 \
        -new \
        -key $pemfile \
        -subj "$SUBJECT" \
        -extensions SAN \
        -config $ssl_config \
        -out $certfile

rm $ssl_config

if $OPENSSL x509 -in $certfile -noout -text | grep -i signature | grep -vi sha256 ; then
    (
        echo $this: WARNING: the cert is not signed with SHA256
        echo $this: this is not fatal, but worth checking
        echo $this: perhaps your OpenSSL needs upgrading
        cat $check
    ) 1>&2
fi

exit 0
