#!/bin/sh

# WARNING: THIS SCRIPT MUST BE KEPT RE-ENTRANT BECAUSE OF THE CALL
# TO `exec` BELOW, WHICH ENABLES ONION PRIVATE-KEY SANITY CHECKING.

# this, and the checker, exist because of:
# https://trac.torproject.org/projects/tor/ticket/29429

GOK_DEPTH_MAX=16
if [ ${GOK_DEPTH=0} -ge $GOK_DEPTH_MAX ] ; then
    echo error: $GOK_DEPTH_MAX is too many attempts to create an onion key, failing
    exit 1
else
    GOK_DEPTH=`expr $GOK_DEPTH + 1`
fi
export GOK_DEPTH

# run this using the `eotk` wrapper,
# otherwise you might not pick up
# the necessary PATH to `tor`, etc...

here=`pwd` # absolute pathnames are required by tor

log=$here/__gok$$.log
dir=$here/__gok$$.dir

mkdir $dir || exit 1
chmod 700 $dir || exit 1
cat >$dir/config <<EOF
DataDirectory $dir/
Log info file $dir/tor.log
PidFile $dir/tor.pid
RunAsDaemon 1
SocksPort 0
HiddenServiceDir $dir
HiddenServicePort 1 127.0.0.1:1
EOF

if [ x$ONION_VERSION = x3 ] ; then
    echo HiddenServiceVersion 3 >> $dir/config
else
    echo HiddenServiceVersion 2 >> $dir/config
fi

tor -f $dir/config >$log 2>&1

loops=0
while [ ! -f $dir/hostname ] ; do
    sleep 1 # wait
    loops=`expr $loops + 1`
    if [ $loops = 30 ] ; then
        echo tor failed to launch in $dir
        kill -TERM `cat $dir/tor.pid` # try to shut it down
        exit 1
    fi
done

kill -TERM `cat $dir/tor.pid` # shut it down

onion=`cat $dir/hostname`
onion=`basename $onion .onion`

if [ x$ONION_VERSION = x3 ] ; then
    pfile=$onion.v3pub.key
    sfile=$onion.v3sec.key
    mv $dir/hs_ed25519_public_key $pfile || exit 1
    mv $dir/hs_ed25519_secret_key $sfile || exit 1
    echo $pfile
    echo $sfile
else
    file=$onion.key
    # sanity-check or re-exec?
    if ! validate-onion-key.py $dir/private_key >/dev/null ; then
        mv $dir/private_key $file,invalid || exit 1
        rm -r $dir $log || exit 1
        exec "$0" "$@" # try again, and trust the recursion-depth-checker
    fi
    mv $dir/private_key $file || exit 1
    echo $file
fi

rm -r $dir $log || exit 1

exit 0
