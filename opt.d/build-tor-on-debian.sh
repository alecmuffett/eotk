#!/bin/sh -x

torversion=0.2.9.9
torsigningkey=6AFEE6D49E92B601

here=`dirname $0`
cd $here || exit 1
here=`pwd`

sudo aptitude install -y libevent-dev zlib1g-dev libssl-dev || exit 1

torurl=https://dist.torproject.org/tor-$torversion.tar.gz
sigurl=https://dist.torproject.org/tor-$torversion.tar.gz.asc
file=`basename $torurl`
sig=`basename $sigurl`
dir=`basename $torurl .tar.gz`

test -f $file || curl -o $file $torurl || exit 1
test -f $sig || curl -o $sig $sigurl || exit 1
gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys $torsigningkey || exit 1
gpg --verify $sig || exit 1
test -d $dir || tar zxf $file || exit 1
cd $dir || exit 1

./configure --prefix=$here || exit 1
make || exit 1
make install || exit 1

cd $here || exit 1
ln -s bin/tor || exit 1

exit 0
