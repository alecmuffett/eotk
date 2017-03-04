#!/bin/sh

cat <<EOF | sudo dd of=/etc/apt/sources.list.d/tor.list
deb http://deb.torproject.org/torproject.org xenial main
deb-src http://deb.torproject.org/torproject.org xenial main
EOF

gpg --keyserver keys.gnupg.net --recv A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 || exit 1
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add - || exit 1

sudo apt-get --yes update || exit 1
sudo apt-get --yes install tor deb.torproject.org-keyring socat python-dev python-pip || exit 1
sudo systemctl stop tor # is there a way to install-without-enable?
sudo systemctl disable tor # we don't need the system to run it

echo ""
echo $0: if you are already running a webserver then nginx will whine about port80, do not worry
sudo apt-get --yes install nginx-extras
sudo systemctl stop nginx # is there a way to install-without-enable?
sudo systemctl disable nginx # we don't need the system to run it

# files and directories
sudo find /var/log/nginx/ -perm -0200 -print0 | sudo xargs -0 chmod g+w || exit 1

echo ""
echo $0: this will probably whine about pip versions, do not worry about it.
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
