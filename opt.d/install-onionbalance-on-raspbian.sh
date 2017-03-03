#!/bin/sh -x

here=`dirname $0`
cd $here || exit 1
here=`pwd`

# install socat for log review
sudo aptitude install -y socat python-pip || exit 1

# install onionbalance
sudo pip install onionbalance || exit 1

# check: this should print `/usr/local/bin/onionbalance`
sudo which onionbalance

# fix/propagate the owner's read/execute-bits
sudo find /usr/local/bin /usr/local/lib -perm -0400 -print0 | sudo xargs -0 chmod a+r
sudo find /usr/local/bin /usr/local/lib -perm -0100 -print0 | sudo xargs -0 chmod a+x

echo this should say: onionbalance 0.1.7 -- or higher
onionbalance --version

exit 0
