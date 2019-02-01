#!/bin/sh

# run this using the `eotk` wrapper, else you might not pick up the
# necessary PATH to `tor`, etc...

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
    mv $dir/private_key $file || exit 1
    echo $file
fi

rm -r $dir $log || exit 1

exit 0
