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

tor -f $dir/config >$log 2>&1

loops=0
while [ ! -f $dir/hostname ] ; do
    sleep 1 # wait
    loops=`expr $loops + 1`
    if [ $loops = 10 ] ; then
        echo tor failed to launch in $dir
        exit 1
    fi
done

kill -TERM `cat $dir/tor.pid` # shut it down

onion=`cat $dir/hostname`
onion=`basename $onion .onion`
file=$onion.key

mv $dir/private_key $file || exit 1

rm -r $dir $log || exit 1

echo $file

exit 0
