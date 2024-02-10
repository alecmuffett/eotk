#!/bin/sh -x

# platform-independent lib.sh
cd `dirname $0` || exit 1
opt_dir=`pwd`
. ./lib.sh || exit 1

# build openssl
SetupOpenSSLVars || exit 1
CustomiseVars || exit 1
SetupForBuild || exit 1
cd $opt_dir || exit 1

# build openresty
SetupOpenRestyVars || exit 1
CustomiseVars || exit 1
SetupForBuild || exit 1
ConfigureOpenRestyWithOpenSSL || exit 1
BuildAndCleanup || exit 1

# cleanup openssl since we needed it around for openresty
rm -rf openssl*

# build tor
SetupTorVars || exit 1
CustomiseVars || exit 1
SetupForBuild || exit 1
ConfigureTor || exit 1
BuildAndCleanup || exit 1

# done
exit 0
