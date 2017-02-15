#!/bin/sh -x

# WORK IN PROGRESS

here=`dirname $0`
cd $here || exit 1
here=`pwd`

# minimal path hack
export PATH=$here/opt.d:$PATH

# OB wants a directory in /var/run, but does not create it
rundir=/var/run/onionbalance
test -d $rundir || sudo mkdir $rundir || exit 1
sudo chmod 01777 $rundir || exit 1

# where shall we put stuff?
OB_TOR_DIR=$here/ob-tor.d
test -d $OB_TOR_DIR || mkdir $OB_TOR_DIR || exit 1

# tor-config
conf=$OB_TOR_DIR/tor.conf
cat > $conf <<EOF
DataDirectory $OB_TOR_DIR
ControlPort unix:$OB_TOR_DIR/tor-control.sock
PidFile $OB_TOR_DIR/tor.pid
Log info file $OB_TOR_DIR/tor.log
SafeLogging 1
HeartbeatPeriod 60 minutes
RunAsDaemon 1
# onionbalance
# SocksPort unix:$OB_TOR_DIR/tor-socks.sock # curl 7.38 does not like this
SocksPort 127.0.0.1:9050 # meh
CookieAuthentication 1
MaxClientCircuitsPending 1024
EOF

# launch tor
tor -f $conf

# launch ob
echo onionbalance -c ob-config.yaml

# done
exit 0
