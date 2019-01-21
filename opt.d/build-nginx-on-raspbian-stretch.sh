#!/bin/sh -x

keyserver=keyserver.ubuntu.com
ngxversion=1.15.8
ngxsigningkey=B0F4253373F8F6F510D42178520A9993A1C052F8

LUAJITURL="http://luajit.org/download/LuaJIT-2.0.5.tar.gz"

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

sudo aptitude install -y libpcre3-dev zlib1g-dev libssl1.0.2 libssl1.0-dev dirmngr || exit 1

# get NGINX and cd into it

ngxurl=http://nginx.org/download/nginx-$ngxversion.tar.gz
ngxsigurl=http://nginx.org/download/nginx-$ngxversion.tar.gz.asc
ngxfile=`basename "$ngxurl"`
ngxsig=`basename "$ngxsigurl"`
ngxdir=`basename "$ngxfile" .tar.gz`

test -f "$ngxfile" || curl -o "$ngxfile" "$ngxurl" || exit 1
test -f $ngxsig || curl -o $ngxsig $ngxsigurl || exit 1
gpg --keyserver hkp://$keyserver:80 --recv-keys $ngxsigningkey || exit 1
gpg --verify $ngxsig || exit 1
test -d "$ngxdir" || tar zxf "$ngxfile" || exit 1

cd $ngxdir || exit 1

src_dir=`pwd`

# make luajiturl

luaurl=$LUAJITURL
luafile=`basename "$luaurl"`
luadir=`basename "$luafile" .tar.gz`

test -f "$luafile" || curl -o "$luafile" "$luaurl" || exit 1
test -d "$luadir" || tar zxf "$luafile" || exit 1

cd $luadir || exit 1

make DESTDIR=$opt_dir install || exit 1

cd $src_dir || exit 1

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
    --with-cc-opt="-fPIE -fstack-protector-strong -fexceptions -D_FORTIFY_SOURCE=2" \
    --with-ld-opt="-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now -Wl,-rpath,$LUAJIT_LIB" \
    --prefix=$opt_dir \
    $OPTS \
    $MODADD || exit 1

make || exit 1

make install || exit 1

cd $opt_dir || exit 1

ln -sf sbin/nginx || exit 1

# cleanup

rm -rf $ngxfile $ngxsig $ngxdir

# done

exit 0
