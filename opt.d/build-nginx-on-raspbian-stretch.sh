#!/bin/sh -x

orversion=1.15.8.3
# All the releases are signed by the public PGP key A0E98066 of Yichun Zhang.

MODS="
https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git
"

OPTS="
--with-http_sub_module
"

# install dir
opt_dir=`dirname $0`
opt_dir=/tmp/foo # CHANGE THIS !!!!!!
cd $opt_dir || exit 1
opt_dir=`pwd`

# dependencies
# CHANGE THIS # sudo aptitude install -y libpcre3-dev zlib1g-dev libssl1.0.2 libssl1.0-dev dirmngr || exit 1

# get OpenResty and cd into it
orurl=https://openresty.org/download/openresty-$orversion.tar.gz
orsigurl=https://openresty.org/download/openresty-1.15.8.3.tar.gz.asc
orfile=`basename "$orurl"`
orsig=`basename "$orsigurl"`
ordir=`basename "$orfile" .tar.gz`
test -f "$orfile" || curl -o "$orfile" "$orurl" || exit 1
test -f "$orsig" || curl -o "$orsig" "$orsigurl" || exit 1
#gpg --keyserver hkp://$keyserver:80 --recv-keys $ngxsigningkey || exit 1
#gpg --verify $ngxsig || exit 1
test -d "$ordir" || tar zxf "$orfile" || exit 1

# build dir
cd $ordir || exit 1
src_dir=`pwd`
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

#    --with-cc-opt="-fPIE -fstack-protector-strong -fexceptions -D_FORTIFY_SOURCE=2" \
#    --with-ld-opt="-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now -Wl,-rpath,$LUAJIT_LIB" \

env \
    ./configure \
    --prefix=$opt_dir \
    $OPTS \
    $MODADD || exit 1

make || exit 1

make install || exit 1

cd $opt_dir || exit 1

ln -sf nginx/sbin/nginx || exit 1

# cleanup

: rm -rf $orfile $orsig $ordir

# done

exit 0
