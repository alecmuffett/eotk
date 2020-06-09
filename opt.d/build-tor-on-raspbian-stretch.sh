#!/bin/sh -x

# platform-independent lib.sh
opt_dir=`dirname $0`
opt_dir=`pwd`
. $opt_dir/lib.sh

# platform dependencies
apt_deps="libevent-dev zlib1g-dev libssl1.0.2 libssl1.0-dev dirmngr"
sudo aptitude install -y $apt_deps || exit 1

# platform-independent build (see lib.sh)
SetupTorVars || exit 1
CustomiseVars || exit 1
SetupForBuild || exit 1
ConfigureTor || exit 1
BuildAndCleanup || exit 1

# done
exit 0
