#!/bin/sh -x
# eotk (c) 2017 Alec Muffett

: if you lack homebrew, see: http://brew.sh/homebrew-nginx/
brew update || exit 1
brew upgrade || exit 1

: install tor, openssl, tools...
brew install openssl tor socat

: do not worry if the next step fails
brew unlink nginx

: install the full nginx
brew tap homebrew/nginx
brew install \
     nginx-full \
     --with-lua-module \
     --with-subs-filter-module \
     --with-headers-more-module

: install onionbalance
sudo easy_install onionbalance # also warms-up sudo

: fix(?) the resulting permissions trainwreck
PYDIRS="/usr/local/bin /usr/local/lib /Library/Python"
sudo find $PYDIRS -perm -0400 -print0 | sudo xargs -0 chmod a+r
sudo find $PYDIRS -perm -0100 -print0 | sudo xargs -0 chmod a+x

: prioritise a sane openssl
BREW_OPENSSL=/usr/local/opt/openssl/bin/openssl
if [ -f $BREW_OPENSSL ] ; then
    ( cd opt.d ; ln -s $BREW_OPENSSL )
fi

exit 0
