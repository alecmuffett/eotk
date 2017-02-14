#!/bin/sh -x

tor=/usr/local/bin/tor

# check these
ONIONBALANCE_STATUS_SOCKET_LOCATION=/tmp/ob-control
ONIONBALANCE_TOR_CONTROL_SOCKET=/tmp/tor-control
export ONIONBALANCE_STATUS_SOCKET_LOCATION ONIONBALANCE_TOR_CONTROL_SOCKET

# OB wants a directory in /var/run, but does not create it
rundir=/var/run/onionbalance
test -d $rundir || sudo mkdir $rundir || exit 1
sudo chmod 01777 $rundir || exit 1

# where we put the config
HS_MASTER=`pwd`/hs-master.d
test -d $HS_MASTER || mkdir $HS_MASTER || exit 1

# make a config file
cat > $HS_MASTER/config <<EOF
DataDirectory $HS_MASTER
HiddenServiceDir $HS_MASTER
ControlPort unix:$HS_MASTER/control.sock
Log info file $HS_MASTER/log.txt
SafeLogging 0
HeartbeatPeriod 60 minutes

HiddenServiceNumIntroductionPoints 10
SocksPort 9050
ControlPort 9051
CookieAuthentication 1
MaxClientCircuitsPending 1024
RunAsDaemon 1
EOF

# launch tor
$tor --hush -f $HS_MASTER/config &

# launch ob
exec sudo onionbalance -c ob-config.yaml
exit 1
