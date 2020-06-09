#!/bin/sh -x

# stdlib
opt_dir=`dirname $0`
opt_dir=`pwd`
. $opt_dir/build.d/lib.sh

# satisfy dependencies
apt_deps="libpcre3-dev zlib1g-dev libssl1.0.2 libssl1.0-dev dirmngr"
sudo aptitude install -y $apt_deps || exit 1

# go
SetupOpenRestyVars || exit 1
CustomiseVars || exit 1
SetupForBuild || exit 1
ConfigureOpenResty || exit 1
BuildAndCleanup || exit 1

# done
exit 0
