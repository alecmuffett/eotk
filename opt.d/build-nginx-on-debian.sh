#!/bin/sh -x

here=`dirname $0`
here=`pwd`
cd $here || exit 1

sudo aptitude install -y libpcre3-dev zlib1g-dev libssl-dev

url=http://nginx.org/download/nginx-1.10.3.tar.gz
file=`basename $url`
dir=`basename $file .tar.gz`

test -f $file || curl -o $file $url || exit 1
test -d $dir || tar zxf $file || exit 1
cd $dir || exit 1

MODS="
https://github.com/openresty/headers-more-nginx-module.git
https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git
"

OPTS="
--with-http_sub_module
--with-http_ssl_module
"

MODADD=""

for modurl in $MODS ; do
    moddir=`basename $modurl .git`
    test -d $moddir || git clone $modurl
    MODADD="$MODADD --add-module=$here/$dir/$moddir"
done

./configure --prefix=$here $OPTS $MODADD || exit 1
make || exit 1
make install || exit 1

cd $here || exit 1
ln -s sbin/nginx || exit 1

exit 0
