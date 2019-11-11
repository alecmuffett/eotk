# Per-platform Installation

## Ubuntu 18.04LTS (prebuilt via tor and canonical)

Install a `ubuntu-18.04.2-live-server-amd64.iso` server instance; and then:

* `git clone https://github.com/alecmuffett/eotk.git`
* `cd eotk`
* `./opt.d/install-everything-on-ubuntu-18.04.sh`
  * this includes a full update

## macOS Mojave (prebuilt via homebrew)

Install [Homebrew](https://brew.sh); and then:

* `git clone https://github.com/alecmuffett/eotk.git`
* `cd eotk`
* `./opt.d/install-everything-on-macos.sh`

## Raspbian (manual builds)

Serially, installation takes about 1h45m on a PiZero, or about 30m on
a Pi3b.  These figures should improve when recent Tor updates sediment
into Raspbian; scripts are supplied for Raspbian "Stretch".

* `sudo apt-get install -y git`
* `git clone https://github.com/alecmuffett/eotk.git`
* `cd eotk`
* `./opt.d/build-nginx-on-raspbian-stretch.sh`
* `./opt.d/build-tor-on-raspbian-stretch.sh`
* `./opt.d/install-onionbalance-on-raspbian-stretch.sh`

## Other Platform Outline Requirements

EOTK requires recent `tor` and also `nginx` with the following modules
enabled; EOTK may need to be told about the modules via
`set nginx_modules_dirs ...`

* `headers_more`
* `ngx_http_substitutions_filter_module`
* `http_sub`
* `http_ssl`
* Lua and/or LuaJIT (ideally from OpenResty)

# Dealing With OnionBalance And Load-Balancing

*NEW FOR 2019:*

OnionBalance as-of June 2019 is an flaky piece of software which is
hard to run on modern Linux because an stale python crypto library;
more than 90% of Onion sites will not practically need it - or, not
initially, anyway - so I am *deprecating OnionBalance in EOTK* until
it is majorly overhauled and also supports v3 onion addressing.

So, I recommend people to avoid OnionBalance and use hardmap (local)
for the moment, until Tor fix it.  Consider OB if and only if your
system is under sustained high bandwidth and strongly demonstrates
extended choking on throughput.

# Dealing With HTTPS Certificates

When connecting to the resulting onions over HTTP/SSL, you will be
using wildcard self-signed SSL certificates - you *will* encounter
many "broken links" which are due to the SSL certificate not being
valid.

This is *expected* and *proper* behaviour; there are currently two
ways to address this.

## Install `mkcert`

The *best* solution for development purposes is to [install `mkcert`
onto the machine which will be running
EOTK](https://github.com/FiloSottile/mkcert#installation) and
configure your own personal Certificate Authority for the certificates
that you will need.

You can then add `set ssl_mkcert 1` to configurations, and your
`mkcert` root certificate will be used to sign the resulting onion
certificates. You can [install that certificate into your local copy
of Tor Browser](docs.d/ADDING-A-ROOT-CERTIFICATE-TO-TOR-BROWSER.md);
of course it will not work for anyone else.

## Visit `/hello-onion/` URLs

The old solution was/is much more manual: EOTK will use OpenSSL to
create certificates, and then, for any onion - eg:
www.a2s3c4d5e6f7g8h9.onion - EOTK provides a fixed url:

* `https://www.a2s3c4d5e6f7g8h9.onion/hello-onion/`

...which (`/hello-onion/`) is internally served by the NGINX proxy and
provides a stable, fixed URL for SSL certificate acceptance; inside
TorBrowser another effective solution is to open all the broken links,
images and resources "in a new Tab" and accept the certificate there.

In production, of course, one would expect to use an SSL EV
certificate to provide identity and assurance to an onion site,
rendering these issues moot.

# Proving Your Ownership To A Certificate Authority / Hardcoded Content

## IMPORTANT: if all of your "proof" URLs have DIFFERENT pathnames?

Small amounts of plain-text page content may be embedded using
regular-expressions for pathnames; this is done using
`hardcoded_endpoint_csv` and the following example will emit
`FOOPROOF` (or `BARPROOF`) for accesses to `/www/.well_known/foo` or
`../.well_known/bar` respectively, ignoring trailing slashes.  Note
the use of double-backslash to escape "dots" in the regular
expression, and use of backslash-indent to continue/enable several
such paths.

```
# demo: CSV list to implement ownership proof URIs for EV SSL issuance
set hardcoded_endpoint_csv \
    ^/www/\\.well_known/foo/?$,"FOOPROOF" \
    ^/www/\\.well_known/bar/?$,"BARPROOF"
```

## IMPORTANT: if all your "well known" URLs have THE SAME pathname?

The `hardcoded_endpoint_csv` hack works okay if all the proof URLs are
different; but if Digicert (or whomever) give you the same pathname
(e.g. `/.well-known/pki-validation/fileauth.txt`) for all of the
onions, what do you do?

Answer: you use "splicing".  If you have onion addresses named
`xxxxxxxxxxxxxxxx` and `yyyyyyyyyyyyyyyy`, then you can create files:

* `templates.d/nginx-site-xxxxxxxxxxxxxxxx.onion.conf`
* `templates.d/nginx-site-yyyyyyyyyyyyyyyy.onion.conf`

...and into each put something similar to the following incantation
- customise as necessary:

```
    location ~ "^/\\.well-known/pki-validation/fileauth\\.txt$" {
      return 200 "RESPECTIVE-XXX-OR-YYY-PROOF-STRING-GOES-HERE";
    }
```

...then when you next `eotk config` and `eotk nxreload`, that code
should be spliced into the correct configuration for each onion.

# Demonstration And Testing

After installation, you can do:

* `./eotk config demo.d/wikipedia.tconf`
  * or: `./eotk config demo.d/wikipedia-v3.tconf`
* `./eotk start wikipedia`
* `./eotk maps -a` # and connect to one of the onions you've created

# Configuring Start-On-Boot, And Logfile Compression

Once you have installed EOTK (below) and configured and tested it
for your project, run:

* `./eotk make-scripts`

This will create two files:

* `./eotk-init.sh` - for installing on your system as a startup script
* `./eotk-housekeeping.sh` - for cronjob log rotation and other cleanup work

Please read the individual files for installation instructions; local
setup is intended to be pretty simple, let me know if anything is
confusing.

# Using EOTK

## I Want To Create My Own Project!

Okay, there are two ways to create your own project:

### Easy With Automatic Onions

Create a config file with a `.tconf` suffix - we'll pretend it's
`foo.tconf` - and use this kind of syntax:

```
set project myproject
hardmap %NEW_ONION% foo.com
hardmap %NEW_ONION% foo.co.uk
hardmap %NEW_ONION% foo.de
```

...and then run

`eotk config foo.tconf`

...which will create the onions for you and will populate a `foo.conf`
for you, and it will then configure EOTK from *that*.  You should
probably *delete* `foo.tconf` afterwards, since forcibly reusing it
would trash your existing onions.

### Slightly Harder With Manually-Mined Onions

* Do `eotk genkey` - it will print the name of the onion it generates
  * Do this as many times as you wish/need.
  * Alternately get a tool like `scallion`, `shallot`, or `eschalot` and use that to "mine" a desirable onion address.
    * https://github.com/katmagic/Shallot - in C, for CPUs
      * Seems okay on Linux, not sure about other platforms
    * https://github.com/lachesis/scallion - in C#, for CPUs & GPUs (GPU == very fast)
      * Advertised as working on Windows, Linux; works well on OSX under "Mono"
    * https://github.com/ReclaimYourPrivacy/eschalot - in C, for CPUs
      * Works well under Linux, and BSD systems. Uses multiple threads. Can use a wordlist to generate onion addresses
    * Be sure to store your mined private keys in `secrets.d` with a
      filename like `a2s3c4d5e6f7g8h9.key` where `a2s3c4d5e6f7g8h9` is
      the corresponding onion address.
* Create a config file with a `.conf` suffix - we'll pretend it's
  `foo.conf` - and use this kind of syntax, substituting
  `a2s3c4d5e6f7g8h9` for the onion address that you generated.

```
set project myproject
hardmap secrets.d/a2s3c4d5e6f7g8h9.key foo.com
```

...and then (IMPORTANT) run:

`eotk config foo.conf`

...which will configure EOTK.

### Then Start Your Project

Like this:

`eotk start myproject`

## What If I Have Subdomains?

When you are setting up the mappings in a config file, you may have to
accomodate "subdomains"; the general form of a internet hostname is
like this:

* `hostname.domain.tld` # like: www.facebook.com or www.gov.uk
  * or: `hostname.domain.sld.tld` # like: www.amazon.co.uk
* `hostname.subdom.domain.tld` # like: www.prod.facebook.com
* `hostname.subsubdom.subdom.domain.tld` # cdn.lhr.eu.foo.net
* `hostname.subsubsubdom.subsubdom.subdom.domain.tld` # ...

...and so on, where:

* tld = [top level domain](https://en.wikipedia.org/wiki/Top-level_domain)
  * sld = [second level domain](https://en.wikipedia.org/wiki/.uk#Second-level_domains)
* domain = *generally the name of the organisation you are interested in*
* subdomain = *some kind of internal structure*
* hostname = *actual computer, or equivalent*

When you are setting up mappings, generally the rules are:

* you will **map one domain per onion**
* you will **ignore all hostnames**
* you will **append all possible subdomain stems**

So if your browser tells you that you are fetching content from
`cdn7.dublin.ireland.europe.foo.co.jp`, you should add a line like:

```
hardmap %NEW_ONION% foo.co.jp europe ireland.europe dublin.ireland.europe
```

...and EOTK should do the rest. All this is necessary purely for
correctness of the self-signed SSL-Certificates - which are going to
be weird, anyway - and the rest of the HTML-rewriting code in EOTK
will be blind to subdomains.

### Subdomain Summary

Subdomains are supported like this, for `dev` as an example:

```
set project myproject
hardmap secrets.d/a2s3c4d5e6f7g8h9.key foo.com dev
```

...and if you have multiple subdomains:

```
hardmap secrets.d/a2s3c4d5e6f7g8h9.key foo.com dev blogs dev.blogs [...]
```

## My Company Has A Lot Of Sites/Domains!

Example:

* `www.foo.com.au`
* `www.syd.foo.com.au`
* `www.per.foo.com.au`,
* `www.cdn.foo.net`
* `www.foo.aws.amazon.com`
* ...

Put them all in the same project as separate mappings, remembering to
avoid the actual "hostnames" as described above:

```
set project fooproj
hardmap %NEW_ONION% foo.com.au syd per
hardmap %NEW_ONION% foo.net cdn
hardmap %NEW_ONION% foo.aws.amazon.com
```

Onion mapping/translations will be applied for all sites in the same project.

## Troubleshooting

The logs for any given project will reside in
`projects.d/<PROJECTNAME>.d/logs.d/`

If something is problematic, first try:

* `git pull` and...
* `eotk config <filename>.conf` again, and then...
* `eotk bounce -a`

### Lots Of Broken Images, Missing Images, Missing CSS

This is probably an SSL/HTTPS thing.

Because of the nature of SSL self-signed certificates, you have to
manually accept the certificate of each and every site for which a
certificate has been created. See the second of the YouTube videos for
some mention of this.

In short: this is normal and expected behaviour.  You can temporarily
fix this by:

* right-clicking on the image for `Open In New Tab`, and accepting the
  certificate
* or using `Inspect Element > Network` to find broken resources, and
  doing the same
* or - if you know the list of domains in advance - visiting the
  `/hello-onion/` URL for each of them, in advance, to accept
  certificates.

If you get an
[official SSL certificate for your onion site](https://blog.digicert.com/ordering-a-onion-certificate-from-digicert/)
then the problem will vanish. Until then, I am afraid that you will be
stuck playing certificate "whack-a-mole".

### NGINX: Bad Gateway

Generally this means that NGINX cannot connect to the remote website,
which usually happens because:

* the site name in the config file, is wrong
* the nginx daemon tries to do a DNS resolution, which fails

Check the NGINX logfiles in the directory cited above, for
confirmation.

If DNS resolution is failing, *PROBABLY* the cause is probably lack
of access to Google DNS / 8.8.8.8; therefore in your config file
you should add a line like this - to use `localhost` as an example:

```
set nginx_resolver 127.0.0.1
```

...and then do:

```
eotk stop -a
eotk config filename.conf
eotk start -a
```

If you need a local DNS resolver, I recommend `dnsmasq`.

### I Can't Connect, It's Just Hanging!

If your onion project has just started, it can take up to a few
minutes to connect for the first time; also sometimes TorBrowser
caches stale descriptors for older onions.  Try restarting TorBrowser
(or use the `New Identity` menu item) and have a cup of tea.  If it
persists, check the logfiles.

### OnionBalance Runs For A Few Days, And Then Just Stops Responding!

Is the clock/time of day correct on all your machines?  Are you
running NTP?  We are not sure but having an incorrect clock may be a
contributory factor to this issue.

## Video Demonstrations

**These videos are instructive, but dated.**

Commands have changed - but not very much - but please check the
documentation rather than trust the videos; consider the videos to be
advisory rather than correct.

* [Basic Introduction to EOTK](https://www.youtube.com/watch?v=ti_VkVmE3J4)
* [Rough Edges: SSL Certificates & Strange Behaviour](https://www.youtube.com/watch?v=UieLTllLPlQ)
* [Using OnionBalance](https://www.youtube.com/watch?v=HNJaMNVCb-U)

[![Basic Introduction to EOTK](http://img.youtube.com/vi/ti_VkVmE3J4/0.jpg)](http://www.youtube.com/watch?v=ti_VkVmE3J4)
[![Rough Edges: SSL Certificates & Strange Behaviour](http://img.youtube.com/vi/UieLTllLPlQ/0.jpg)](http://www.youtube.com/watch?v=UieLTllLPlQ)
[![Using OnionBalance](http://img.youtube.com/vi/HNJaMNVCb-U/0.jpg)](http://www.youtube.com/watch?v=HNJaMNVCb-U)
