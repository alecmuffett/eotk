#!/bin/sh -x
# eotk (c) 2017 Alec Muffett

# if you lack homebrew, see: http://brew.sh/homebrew-nginx/

brew update
brew upgrade
: do not worry if the next step fails
brew unlink nginx
brew tap homebrew/nginx
brew install nginx-full --with-subs-filter-module --with-headers-more-module
brew install openssl tor
