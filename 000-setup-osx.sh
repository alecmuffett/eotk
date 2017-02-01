#!/bin/sh
# eotk (c) 2017 Alec Muffett

# if you lack homebrew, see: http://brew.sh/homebrew-nginx/

brew unlink nginx # this may fail if not installed
brew tap homebrew/nginx
brew install nginx-full --with-subs-filter-module --with-headers-more-module
brew install openssl dnsmasq tor
brew update
brew upgrade
