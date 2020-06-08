#!/bin/sh -x
tool=tor
tool_version=0.4.3.5
tool_signing_key="6AFEE6D49E92B601 C218525819F78451"
tool_url=https://dist.torproject.org/tor-$tool_version.tar.gz
tool_sig_url=https://dist.torproject.org/tor-$tool_version.tar.gz.asc
apt_deps="libevent-dev zlib1g-dev libssl1.0.2 libssl1.0-dev dirmngr"
sub_path="bin/$tool"
keyserver=keyserver.ubuntu.com

# install dir
opt_dir=`dirname $0`
cd $opt_dir || exit 1
opt_dir=`pwd`
install_dir=$opt_dir/$tool.d

# dependencies
sudo aptitude install -y $apt_deps || exit 1

# get $tool and cd into it
tool_tarball=`basename "$tool_url"`
tool_sig=`basename "$tool_sig_url"`
tool_dir=`basename "$tool_tarball" .tar.gz`
test -f "$tool_tarball" || curl -o "$tool_tarball" "$tool_url" || exit 1
test -f "$tool_sig" || curl -o "$tool_sig" "$tool_sig_url" || exit 1
gpg --keyserver hkp://$keyserver:80 --recv-keys $tool_signing_key || exit 1
gpg --verify $tool_sig || exit 1
test -d "$tool_dir" || tar zxf "$tool_tarball" || exit 1

# build dir
cd $tool_dir || exit 1

# configure and build
./configure --prefix=$install_dir || exit 1
make || exit 1
make install || exit 1

# link the binary for EOTK access ($opt_dir is in $PATH)
cd $opt_dir || exit 1
ln -sf $install_dir/$sub_path || exit 1

# cleanup
rm -rf $tool_tarball $tool_sig $tool_dir

# done
exit 0
