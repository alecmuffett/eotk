#!/bin/sh -x

# WORK IN PROGRESS

EOTK_HOME=`dirname $0`
cd $EOTK_HOME || exit 1
EOTK_HOME=`pwd`

# minimal path hack
export PATH=$EOTK_HOME/opt.d:$PATH
project_dir=$EOTK_HOME/projects.d

# where shall we put stuff?
ob_dir=$project_dir/onionbalance.run
test -d $ob_dir || mkdir $ob_dir || exit 1

# config files
ob_conf=$ob_dir/config.yaml
tor_conf=$ob_dir/tor.conf
tor_control=$ob_dir/tor-control.sock

# make tor conf
cat > $tor_conf <<EOF
DataDirectory $ob_dir
ControlPort unix:$tor_control
PidFile $ob_dir/tor.pid
Log info file $ob_dir/tor.log
SafeLogging 1
HeartbeatPeriod 60 minutes
RunAsDaemon 1
# onionbalance
# SocksPort unix:$ob_dir/tor-socks.sock # curl 7.38 does not like this
SocksPort 127.0.0.1:9050 # meh
CookieAuthentication 1
MaxClientCircuitsPending 1024
EOF

# launch tor
echo tor -f $tor_conf

# launch ob
echo onionbalance -s $tor_control -c $ob_conf -v info

# done
exit 0
