#!/bin/sh -x

# platform-independent lib.sh
opt_dir=`dirname $0`
opt_dir=`pwd`
. $opt_dir/lib.sh

# platform dependencies
shared_deps="
gmake
libevent
"
: pkg install $shared_deps || exit 1

# build openresty
: SetupOpenRestyVars || exit 1
: CustomiseVars || exit 1
: SetupForBuild || exit 1
: ConfigureOpenResty || exit 1
: BuildAndCleanup || exit 1

# build tor
SetupTorVars || exit 1
CustomiseVars || exit 1
SetupForBuild || exit 1
ConfigureTor || exit 1
BuildAndCleanup || exit 1

# done
exit 0
