#!/bin/sh

OPT_DIR=`dirname $0`
EOTK_HOME=`( cd $OPT_DIR/.. ; pwd )` # glib assumption

PACKAGES="
deb.torproject.org-keyring
nginx-extras
python-dev
python-pip
socat
tor
"

TORSIG=A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
EOTK="eotkinst"

cat <<EOF | sudo dd of=/etc/apt/sources.list.d/tor.list
deb https://deb.torproject.org/torproject.org bionic main
deb-src https://deb.torproject.org/torproject.org bionic main
EOF

# gpg keyservers are no more, alas
curl https://deb.torproject.org/torproject.org/$TORSIG.asc | gpg --import || exit 1
gpg --export $TORSIG | sudo apt-key add - || exit 1

# install everything in one go
echo ""
echo "$EOTK: if you are already running a webserver, nginx may complain about port80"
echo "$EOTK: if such happens, do not worry, because we will soon disable nginx..."
sudo apt install -y apt-transport-https || exit 1
sudo apt update || exit 1
sudo apt upgrade -y || exit 1
sudo apt install -y $PACKAGES || exit 1
sudo systemctl stop tor nginx || exit 1
sudo systemctl disable tor nginx || exit 1

# install python stuff
echo ""
echo $EOTK: this command may complain about pip versions, do not worry about it.
sudo pip install onionbalance || exit 1

# fix files and directories
sudo find /var/log/nginx/ -perm -0200 -print0 | sudo xargs -0 chmod g+w || exit 1
sudo find /usr/local/bin /usr/local/lib -perm -0400 -print0 | sudo xargs -0 chmod a+r || exit 1
sudo find /usr/local/bin /usr/local/lib -perm -0100 -print0 | sudo xargs -0 chmod a+x || exit 1

site_conf=$EOTK_HOME/eotk-site.conf
echo ""
echo "$EOTK: Adding site-specific configuration to: $site_conf"
(
    echo "# setting nginx_modules_dirs is essential for use on Ubuntu 18.04"
    echo "set nginx_modules_dirs /etc/nginx/modules-enabled"
    echo ""
) >> $site_conf

echo ""
echo "$EOTK: done"
exit 0
