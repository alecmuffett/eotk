#!/bin/sh -x

here=`dirname $0`
here=`pwd`
cd $here || exit 1

sudo aptitude install libevent-dev zlib1g-dev libssl-dev || exit 1

url=https://dist.torproject.org/tor-0.2.9.9.tar.gz
file=`basename $url`
dir=`basename $url .tar.gz`

test -f $file || curl -o $file $url || exit 1
test -d $dir || tar zxf $file || exit 1
cd $dir || exit 1

./configure --prefix=$here || exit 1
make || exit 1
make install || exit 1

cd $here || exit 1
ln -s bin/tor || exit 1

exit 0
