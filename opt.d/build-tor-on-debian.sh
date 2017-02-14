#!/bin/sh -x

torversion=0.2.9.9
torsigningkey=6AFEE6D49E92B601

here=`dirname $0`
cd $here || exit 1
here=`pwd`

sudo aptitude install -y libevent-dev zlib1g-dev libssl-dev || exit 1

torurl=https://dist.torproject.org/tor-$torversion.tar.gz
torsigurl=https://dist.torproject.org/tor-$torversion.tar.gz.asc
torfile=`basename $torurl`
torsig=`basename $torsigurl`
tordir=`basename $torurl .tar.gz`

test -f $torfile || curl -o $torfile $torurl || exit 1
test -f $torsig || curl -o $torsig $torsigurl || exit 1
gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys $torsigningkey || exit 1
gpg --verify $torsig || exit 1
test -d $tordir || tar zxf $torfile || exit 1
cd $tordir || exit 1

./configure --prefix=$here || exit 1
make || exit 1
make install || exit 1

cd $here || exit 1
ln -s bin/tor || exit 1

rm -rf $torfile $torsig $tordir

exit 0
