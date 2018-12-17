#!/bin/sh -x
# eotk (c) 2017 Alec Muffett

: if you lack homebrew, see: http://brew.sh/homebrew-nginx/
brew update || exit 1
brew upgrade || exit 1

: install tor, openssl, tools...
brew install openssl tor socat

: do not worry if the next few steps fail
(
    brew unlink nginx # unlink old copy
    brew uninstall nginx # remove old copy
    brew uninstall nginx-full # remove old copy
    brew untap homebrew/nginx # remove the tap which interferes with install
)

# ref: https://github.com/denji/homebrew-nginx

NGINX_MODULES="
--with-lua-module
--with-subs-filter-module
--with-headers-more-module
"

: install the full nginx
brew tap denji/nginx && brew install nginx-full $NGINX_MODULES || exit 1

: install onionbalance
sudo easy_install onionbalance # also warms-up sudo

: fix the resulting permissions trainwreck
PYDIRS="/usr/local/bin /usr/local/lib /Library/Python"
sudo find $PYDIRS -perm -0400 -print0 | sudo xargs -0 chmod a+r
sudo find $PYDIRS -perm -0100 -print0 | sudo xargs -0 chmod a+x

: prioritise a sane openssl
BREW_OPENSSL=/usr/local/opt/openssl/bin/openssl
optdir=`dirname $0`
if [ -f $BREW_OPENSSL ] ; then
    ( cd $optdir ; ln -sf $BREW_OPENSSL )
fi

exit 0
