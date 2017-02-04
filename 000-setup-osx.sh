#!/bin/sh -x
# eotk (c) 2017 Alec Muffett

# if you lack homebrew, see: http://brew.sh/homebrew-nginx/

brew update || exit 1
brew upgrade || exit 1

: install tor and openssl
brew install openssl tor

: do not worry if the next step fails
brew unlink nginx

: go for the full nginx
brew tap homebrew/nginx
brew install nginx-full --with-subs-filter-module --with-headers-more-module

: prioritise a sane openssl

BREW_OPENSSL=/usr/local/opt/openssl/bin/openssl

if [ -f $BREW_OPENSSL ] ; then
    ( cd opt.d ; ln -s $BREW_OPENSSL )
fi


exit 0
