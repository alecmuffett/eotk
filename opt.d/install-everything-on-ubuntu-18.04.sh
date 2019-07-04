#!/bin/sh

apt install apt-transport-https

cat <<EOF | sudo dd of=/etc/apt/sources.list.d/tor.list
deb https://deb.torproject.org/torproject.org bionic main
deb-src https://deb.torproject.org/torproject.org bionic main
EOF

TORSIG=A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
gpg --keyserver keys.gnupg.net --recv $TORSIG || exit 1
gpg --export $TORSIG | sudo apt-key add - || exit 1

sudo apt update || exit 1
sudo apt install tor deb.torproject.org-keyring socat python-dev python-pip || exit 1
sudo systemctl stop tor # is there a way to install-without-enable?
sudo systemctl disable tor # we don't need the system to run it

echo ""
echo $0: if you are already running a webserver then nginx will complain about port80, do not worry
sudo apt install nginx-extras
sudo systemctl stop nginx # is there a way to install-without-enable?
sudo systemctl disable nginx # we don't need the system to run it

# files and directories
sudo find /var/log/nginx/ -perm -0200 -print0 | sudo xargs -0 chmod g+w || exit 1

echo ""
echo $0: this will probably complain about pip versions, do not worry about it.
sudo pip install onionbalance || exit 1
sudo find /usr/local/bin /usr/local/lib -perm -0400 -print0 | sudo xargs -0 chmod a+r || exit 1
sudo find /usr/local/bin /usr/local/lib -perm -0100 -print0 | sudo xargs -0 chmod a+x || exit 1

echo ""
echo IMPORTANT: some versions of Ubuntu packages are unfortunately old.
echo Because of this, when starting projects you may see messages like:
echo ">" could not open error log file: open /var/log/nginx/error.log failed
echo ...and these specific messages may be safely ignored.
echo done.

exit 0
