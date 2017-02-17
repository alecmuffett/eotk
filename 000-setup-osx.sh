#!/bin/sh -x
# eotk (c) 2017 Alec Muffett

# if you lack homebrew, see: http://brew.sh/homebrew-nginx/

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

: prioritise a sane openssl

BREW_OPENSSL=/usr/local/opt/openssl/bin/openssl

if [ -f $BREW_OPENSSL ] ; then
    ( cd opt.d ; ln -s $BREW_OPENSSL )
fi

exit 0
