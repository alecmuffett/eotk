# Setting up EOTK on Raspbian

exit 0 # just in case anyone thinks this is a script

# Tor Installation

EOTK requires Tor 0.2.9.9+

# NGINX Installation

EOTK requires recent `nginx` with the following modules/features enabled:

* `headers_more`
* `ngx_http_substitutions_filter_module`
* `http_sub`
* `http_ssl`

# Summary

Unless you are fortunate to have these already installed, there are
two options for you:

- spend hours on your own, messing with `backports` and repos, or:
- run the obviously-named scripts in opt.d to compile from source.

...which will do all the work for you, no options/arguments required,
although the actual compilation may take a long time.  It's your
choice.  If you choose the latter option, do this:

- `./opt.d/build-nginx-on-debian.sh`
- `./opt.d/build-tor-on-debian.sh`

...as appropriate.

# OnionBalance and `softmap`

## STOP AND READ THIS BIT

If you are just experimenting for fun then you can probably skip the
rest of these instructions; adding `onionbalance` enables you to use
the `softmap` feature which is only really interesting if you are
going to be running a high-bandwidth, heavily-trafficked site.

## What Is Needed?

To use "softmap", OnionBalance needs to be installed on one (i.e. 1)
machine, which:

* may or may-not also be a "worker" (your choice)
* should be of the same architecture as all the other/worker machines, if any
* will be the only machine that needs access to the "master" onion address
* will serve as the master copy of NGINX and Tor configurations
  * from which all others (if any) will rsync
* needs to be able to `ssh` and `rsync`-over-`ssh` to all worker machines (if any)

## A Note About `pip`

I understand that `pip` is the more advanced packaging tool, but using
it on either of OSX or Debian Jesse seems to exacerbate the conflicts
with already-installed software. It has been a lot less troubling
(from experience) to just go with `easy_install`

If you're knowledgeable enough to want to argue about this point then
I shall welcome your input in the form of `Issues` logged against
EOTK; but please be aware that that means you are probably not my main
audience.  Or you can install `pip` of your own accord, and use that
to install `onionbalance`, with my blessing.

## Installation On Debian / Raspbian / Ubuntu

Do:

```
# install onionbalance
sudo easy_install onionbalance # also warms-up sudo

# install socat for log review
sudo aptitude install socat

# check: this should print `/usr/local/bin/onionbalance`
sudo which onionbalance

# fix/propagate the owner's read-bit
sudo find /usr/local/bin /usr/local/lib -perm -0400 -print0 | sudo xargs -0 chmod a+r

# fix/propagate the owner's execute-bit
sudo find /usr/local/bin /usr/local/lib -perm -0100 -print0 | sudo xargs -0 chmod a+x

# check: this should say `onionbalance 0.1.7` or higher
onionbalance --version
```
