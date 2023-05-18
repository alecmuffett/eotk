#!/bin/sh -x

# platform-independent lib.sh
cd `dirname $0` || exit 1
opt_dir=`pwd`
. ./lib.sh || exit 1

# platform dependencies
shared_deps="
build-essential
curl
dirmngr
libevent-dev
libpcre3-dev
libssl-dev
libssl1.1
make
perl
zlib1g-dev
"
sudo apt install -y $shared_deps || exit 1

# build openresty
SetupOpenRestyVars || exit 1
CustomiseVars || exit 1
SetupForBuild || exit 1
ConfigureOpenResty || exit 1
BuildAndCleanup || exit 1

# build tor
SetupTorVars || exit 1
CustomiseVars || exit 1
SetupForBuild || exit 1
ConfigureTor || exit 1
BuildAndCleanup || exit 1

# done
exit 0
