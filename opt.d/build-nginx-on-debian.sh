#!/bin/sh -x

ngxversion=1.10.3
ngxsigningkey=B0F4253373F8F6F510D42178520A9993A1C052F8

LUAJITURL="https://luajit.org/download/LuaJIT-2.0.3.tar.gz"

MODS="
https://github.com/openresty/headers-more-nginx-module.git
https://github.com/openresty/lua-nginx-module.git
https://github.com/simpl/ngx_devel_kit.git
https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git
"

OPTS="
--with-http_sub_module
--with-http_ssl_module
"

opt_dir=`dirname $0`
cd $opt_dir || exit 1
opt_dir=`pwd`

# dependencies

sudo aptitude install -y libpcre3-dev zlib1g-dev libssl-dev || exit 1

# get NGINX and cd into it

ngxurl=https://nginx.org/download/nginx-$ngxversion.tar.gz
sigurl=https://nginx.org/download/nginx-$ngxversion.tar.gz.asc
file=`basename "$ngxurl"`
sig=`basename "$sigurl"`
dir=`basename "$file" .tar.gz`
test -f "$file" || curl -o "$file" "$ngxurl" || exit 1
test -f $sig || curl -o $sig $sigurl || exit 1
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys $ngxsigningkey || exit 1
gpg --verify $sig || exit 1
test -d "$dir" || tar zxf "$file" || exit 1

cd $dir || exit 1
src_dir=`pwd`

# make luajiturl

luaurl=$LUAJITURL
file=`basename "$luaurl"`
dir=`basename "$file" .tar.gz`
test -f "$file" || curl -o "$file" "$luaurl" || exit 1
test -d "$dir" || tar zxf "$file" || exit 1

(
    cd $dir || exit 1
    make DESTDIR=$opt_dir install
)

# get mods

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

# make NGINX

export LUAJIT_LIB=$opt_dir/usr/local/lib
export LUAJIT_INC=$opt_dir/usr/local/include/luajit-2.0

env \
    ./configure \
    --with-ld-opt="-Wl,-rpath,$LUAJIT_LIB" \
    --prefix=$opt_dir \
    $OPTS \
    $MODADD || exit 1

make || exit 1

make install || exit 1

cd $opt_dir || exit 1

ln -s sbin/nginx || exit 1

exit 0
