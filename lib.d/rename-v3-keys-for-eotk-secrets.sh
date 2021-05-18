#!/bin/sh

# Version 3 onion addresses require explicit declaration of the
# onion-address AS WELL AS the key materials; for simplicity and
# clarity we embed the onion address in the filenames, and we need two
# filenames for the two files.

self=`basename $0`
hostname=hostname
public=hs_ed25519_public_key
secret=hs_ed25519_secret_key

Fatal() {
    echo "fatal error: $0: $@" 1>&2
    exit 1
}

for f in $hostname $public $secret ; do
    test -f $f || Fatal "cannot file file '$f' for data"
done

onion=`cat hostname` || Fatal "cannot read 'hostname' file to establish onion address"
onion=`basename $onion .onion` # strip verbiage
echo $onion | egrep '^[2-7a-z]{56}$' >/dev/null || Fatal 'bad format onion address '$onion''

public2="$onion.v3pub.key"
secret2="$onion.v3sec.key"

cp $public $public2 || Fatal "cannot copy $public to $public2"
cp $secret $secret2 || Fatal "cannot copy $secret to $secret2"

echo $public2
echo $secret2
