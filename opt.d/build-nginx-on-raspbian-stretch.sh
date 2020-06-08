#!/bin/sh -x
tool=openresty
tool_version=1.15.8.3 # All the releases are signed by the public PGP key A0E98066 of Yichun Zhang.
MODS="https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git"
OPTS="--with-http_sub_module"

# install dir
opt_dir=`dirname $0`
cd $opt_dir || exit 1
opt_dir=`pwd`
install_dir=$opt_dir/$tool # have to bury the tool because of name clashes

# dependencies # CHANGE THIS
# sudo aptitude install -y libpcre3-dev zlib1g-dev libssl1.0.2 libssl1.0-dev dirmngr || exit 1

# get OpenResty and cd into it
tool_url=https://openresty.org/download/openresty-$tool_version.tar.gz
tool_sig_url=https://openresty.org/download/openresty-1.15.8.3.tar.gz.asc
tool_tarball=`basename "$tool_url"`
tool_sig=`basename "$tool_sig_url"`
tool_dir=`basename "$tool_tarball" .tar.gz`
test -f "$tool_tarball" || curl -o "$tool_tarball" "$tool_url" || exit 1
test -f "$tool_sig" || curl -o "$tool_sig" "$tool_sig_url" || exit 1
#gpg --keyserver hkp://$keyserver:80 --recv-keys $ngxsigningkey || exit 1
#gpg --verify $ngxsig || exit 1
test -d "$tool_dir" || tar zxf "$tool_tarball" || exit 1

# build dir
cd $tool_dir || exit 1
src_dir=`pwd`
cd $src_dir || exit 1

# get the mods
MODADD=""
for modurl in $MODS ; do
    moddir=`basename $modurl .git`
    if [ -d $moddir ] ; then
        ( cd $moddir ; exec git pull ) || exit 1
    else
        git clone $modurl || exit 1
    fi
    MODADD="$MODADD --add-module=$src_dir/$moddir"
done

# configure and build
env ./configure --prefix=$install_dir $OPTS $MODADD || exit 1
# --with-cc-opt="-fPIE -fstack-protector-strong -fexceptions -D_FORTIFY_SOURCE=2" \
# --with-ld-opt="-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now -Wl,-rpath,$LUAJIT_LIB" \
make || exit 1
make install || exit 1

# link the binary for EOTK access ($opt_dir is in $PATH)
cd $opt_dir || exit 1
ln -sf $tool/nginx/sbin/nginx || exit 1

# cleanup
: rm -rf $tool_tarball $tool_sig $tool_dir

# done
exit 0
