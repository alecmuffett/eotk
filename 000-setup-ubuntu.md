# Setting up EOTK on Ubuntu

exit 0 # just in case anyone thinks this is a script

* We will assume that you are running Ubuntu Server 16.04.1
  * Your mileage may vary

If running on Ubuntu 16.04 the NGINX modules are outdated, and there
may be issues with permissions; in case of failure, or if you want to
run the most up to date code, use the raspbian-build scripts in
`opt.d` to create a fresh copy.

# Tor Installation

EOTK requires Tor 0.2.9.9+

In a browser elsewhere, retreive the instructions for installing Tor
from https://www.torproject.org/docs/debian.html.en

## Installation Process (MANUAL)

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

# NGINX Installation

EOTK requires recent `nginx` with the following modules/features enabled:

* `headers_more`
* `ngx_http_substitutions_filter_module`
* `http_sub`
* `http_ssl`

## Installation Process

* `sudo apt-get install nginx-extras`
* `sudo find /var/log/nginx/ -type f -perm -0200 -print0 | sudo xargs -0 chmod g+w`

# OnionBalance Installation

Necessary for `softmap` and load-balancing; using `pip` tends to
mangle permissions, hence the find/xargs-chmod commands.

## Installation Process

* `sudo apt-get install socat python-pip`
* `sudo pip install onionbalance`
* `sudo find /usr/local/bin /usr/local/lib -perm -0400 -print0 | sudo xargs -0 chmod a+r`
* `sudo find /usr/local/bin /usr/local/lib -perm -0100 -print0 | sudo xargs -0 chmod a+x`

Finally, this should say: onionbalance 0.1.7 -- or higher

`onionbalance --version`
