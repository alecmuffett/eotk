#!/bin/sh -x

LUAJITURL="http://luajit.org/download/LuaJIT-2.0.3.tar.gz"

MODS="
https://github.com/openresty/headers-more-nginx-module.git
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

sudo aptitude install -y libpcre3-dev zlib1g-dev libssl-dev

# get NGINX and cd into it

url=http://nginx.org/download/nginx-1.10.3.tar.gz
file=`basename "$url"`
dir=`basename "$file" .tar.gz`
test -f "$file" || curl -o "$file" "$url" || exit 1
test -d "$dir" || tar zxf "$file" || exit 1

cd $dir || exit 1
src_dir=`pwd`

# make luajiturl

url=$LUAJITURL
file=`basename "$url"`
dir=`basename "$file" .tar.gz`
test -f "$file" || curl -o "$file" "$url" || exit 1
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
