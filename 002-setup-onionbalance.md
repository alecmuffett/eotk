# Steps To Install OnionBalance

## STOP AND READ THIS

If you are just experimenting for fun then you can probably skip these
instructions; adding `onionbalance` enables you to use the `softmap`
feature which is only really interesting if you are going to be
running a high-bandwidth, heavily-trafficked site.

# TODO

* All this will be scripted.

# What This Does / What Needs To Happen

OnionBalance needs to be installed on one (i.e. 1) machine, which:

* may or may-not also be a "worker" (your choice)
* should be of the same architecture as all the other/worker machines, if any
* will be the only machine that needs access to the "master" onion address
* will serve as the master copy of NGINX and Tor configurations
  * from which all others (if any) will rsync
* needs to be able to `ssh` and `rsync`-over-`ssh` to all worker machines (if any)

# A Note About `pip`

I understand that `pip` is the more advanced packaging tool, but using
it on either of OSX or Debian Jesse seems to exacerbate the conflicts
with already-installed software. It has been a lot less troubling
(from experience) to just go with `easy_install`

If you're knowledgeable enough to want to argue about this point then
I shall welcome your input in the form of `Issues` logged against
EOTK; but please be aware that that means you are probably not my main
audience.  Or you can install `pip` of your own accord, and use that
to install `onionbalance`, with my blessing.

# Installation

## Basic Installation

## On OSX

`sudo easy_install onionbalance`

That's the easy part, done.  Next:

# Fixing The Resulting Permissions Nightmare

`easy_install` (and `pip`) have no credible sense of installation
permissions, and so everything ends up being owned by `root` and
lacking `world` permissions.

EOTK is meant to be runnable as non-root users, so therefore we need
to fix this silliness.

## On OSX

To Be Documented.

## Debian / Raspbian / Ubuntu

Do:

```
# become root
sudo -i

# check: this should print `/usr/local/bin/onionbalance`
which onionbalance

# fix/propagate the owner's read-bit
find /usr/local/bin /usr/local/lib -perm -0400 -print0 | xargs -0 chmod a+r

# fix/propagate the owner's execute-bit
find /usr/local/bin /usr/local/lib -perm -0100 -print0 | xargs -0 chmod a+x

# install socat for log review
aptitude install socat

# exit root
exit

# check: this should say `onionbalance 0.1.7` or higher
onionbalance --version
```
