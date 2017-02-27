#!/bin/sh

cat <<EOF | sudo dd of=/etc/apt/sources.list.d/tor.list
deb http://deb.torproject.org/torproject.org xenial main
deb-src http://deb.torproject.org/torproject.org xenial main
EOF

gpg --keyserver keys.gnupg.net --recv A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89

gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -

sudo apt-get update

apt-get install tor deb.torproject.org-keyring nginx-extras socat python-pip

sudo find /var/log/nginx/ -type f -perm -0200 -print0 | sudo xargs -0 chmod g+w

sudo pip install onionbalance

sudo find /usr/local/bin /usr/local/lib -perm -0400 -print0 | sudo xargs -0 chmod a+r

sudo find /usr/local/bin /usr/local/lib -perm -0100 -print0 | sudo xargs -0 chmod a+x

exit 0
