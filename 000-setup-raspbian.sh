#!/bin/sh

tor_url=https://www.torproject.org/dist/tor-0.2.9.9.tar.gz

cat <<EOF

As of February 2017, you will need Raspbian's Jessie Backports to
obtain a recent copy of NGINX, version 1.9 or above.

To do this:

### add jessie-backports to sources.list
echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list.d/jessie-backports.list

### optionally add sources, as well ... it's GNU after all :)
echo "deb-src http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list.d/jessie-backports.list

### refresh
apt-get update

### install it from backports
apt-get -t jessie-backports install nginx







== Firstly... ==

If you don't already have it, please install tor 0.2.9.9 or later;
I would love to help with this but I don't want to get into the
nightmare of telling you to set up "backports" and so forth.

For ARM/Raspbian, I would recommend downloading:

  $tor_url

...and installing it appropriately / with defaults.

If you want to do that, there is a script you can run:

  ./tools/build-tor-on-debian.sh

...which will do this for you.

Please:

 1) press return to continue, if you already have a recent "tor", or...
 2) or use ^C if you want to exit, so you can build it

EOF
read junk

##################################################################

# now we install the other stuff

sudo aptitude install nginx-full

exit 0
