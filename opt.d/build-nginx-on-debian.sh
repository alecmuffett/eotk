#!/bin/sh -x

#sudo aptitude install libpcre3-dev zlib1g-dev libssl-dev

where=/tmp/nginx

test -d $where || mkdir -p $where || exit 1

url=http://nginx.org/download/nginx-1.10.3.tar.gz

file=`basename $url`

dir=`basename $file .tar.gz`

test -f $file || wget $url

test -d $dir || tar zxf $file

cd $dir || exit 1

here=`pwd`

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
    MODADD="$MODADD --add-module=$here/$moddir"
done

./configure --prefix=$where $OPTS $MODADD

make

make install
