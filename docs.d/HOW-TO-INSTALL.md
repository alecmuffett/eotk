# Notes

EOTK requires Tor 0.3.5.7+

# Requirements

EOTK requires recent `nginx` with the following modules/features enabled:

* `headers_more`
* `ngx_http_substitutions_filter_module`
* `http_sub`
* `http_ssl`
* Lua and/or LuaJIT (ideally from OpenResty)

# After the Installation

Once you have installed EOTK (below) and configured and tested it 
for your project, run:

* `eotk make-scripts`

This will create two files: 

* `eotk-init.sh` - for installing on your system as a startup script
* `eotk-housekeeping.sh` - for cronjob log rotation and other cleanup work

Please read the individual files for installation instructions; 
it's intended to be pretty simple.

# Per-Platform Installations

Where you don't have Tor, NGINX or OnionBalance, 
or much other stuff currently installed:

## macOS Mojave (prebuilt via homebrew)

* install Homebrew: http://brew.sh
* `git clone https://github.com/alecmuffett/eotk.git`
* `cd eotk`
* `./opt.d/install-everything-on-macos.sh`

## Ubuntu 16.04 (prebuilt via tor and canonical)

* `git clone https://github.com/alecmuffett/eotk.git`
* `cd eotk`
* `./opt.d/install-everything-on-ubuntu-16.04.sh`

## Raspbian (manual builds)

Serially, this takes about 1h45m on a PiZero, or about 30m on a Pi3b.
These figures should improve when recent Tor updates sediment into Raspbian.

Scripts are supplied for stretch

* `sudo apt-get install -y git`
* `git clone https://github.com/alecmuffett/eotk.git`
* `cd eotk`
* `./opt.d/build-nginx-on-raspbian-stretch.sh`
* `./opt.d/build-tor-on-raspbian-stretch.sh`
* `./opt.d/install-onionbalance-on-raspbian-stretch.sh`

# Piecemeal Installation Notes

You only need this section if you have to do installation in bits
because pre-existing software:

## Ubuntu Tor Installation

In a browser elsewhere, retreive the instructions for installing Tor
from https://www.torproject.org/docs/debian.html.en

* Set the menu options for:
  * run *Ubuntu Xenial Xerus*
  * and want *Tor*
  * and version *stable*
  * and read what is now on the page.
* Configure the APT repositories for Tor
  * I recommend that you add the tor repositories into a new file
    * Use: `/etc/apt/sources.list.d/tor.list` or similar
* Do the gpg thing
* Do the apt update thing
* Do the tor installation thing

## Ubuntu NGINX Installation

Through `apt-get`; logfiles are tweaked to be writable by admin users.

* `sudo apt-get install nginx-extras`
* `sudo find /var/log/nginx/ -type f -perm -0200 -print0 | sudo xargs -0 chmod g+w`

## Ubuntu OnionBalance Installation

Through `apt-get` and `pip`; using `pip` tends to mangle permissions,
hence the find/xargs-chmod commands.

* `sudo apt-get install socat python-pip`
* `sudo pip install onionbalance`
* `sudo find /usr/local/bin /usr/local/lib -perm -0400 -print0 | sudo xargs -0 chmod a+r`
* `sudo find /usr/local/bin /usr/local/lib -perm -0100 -print0 | sudo xargs -0 chmod a+x`
