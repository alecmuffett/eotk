#!/bin/sh -x

here=`dirname $0`
cd $here || exit 1
here=`pwd`

# install socat for log review
sudo aptitude install socat python-setuptools

# install onionbalance
sudo easy_install onionbalance # also warms-up sudo

# check: this should print `/usr/local/bin/onionbalance`
sudo which onionbalance

# fix/propagate the owner's read-bit
sudo find /usr/local/bin /usr/local/lib -perm -0400 -print0 | sudo xargs -0 chmod a+r

# fix/propagate the owner's execute-bit
sudo find /usr/local/bin /usr/local/lib -perm -0100 -print0 | sudo xargs -0 chmod a+x

echo this should say: onionbalance 0.1.7 -- or higher
onionbalance --version

exit 0
