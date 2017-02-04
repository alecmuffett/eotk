# The Enterprise Onion Toolkit
## eotk (c) 2017 Alec Muffett

# Status - ALPHA

The EOTK goal is to provide a tool for prototyping, and deploying at
scale, HTTP and HTTPS onion sites to provide official presence for
popular websites.

The results are essentially a "man in the middle" proxy; set them up
only for your own sites or for sites which do not require login
credentials of any kind.

The resulting NGINX configs are probably both buggy and not terribly
well tuned; please consider this project to be very much "early days",
but I shall try not to modify the configuration file format.

The `softmap` support is untested, and needs some more work to make it
nice to launch and integrate with OnionBalance; please avoid it for
the moment.

## Usage Notes

When connecting to the resulting onions over HTTP/SSL, you will be
using wildcard self-signed SSL certificates - you *will* encounter
many "broken links" which are due to the SSL certificate not being
valid.  This is *expected* and *proper* behaviour.

To help cope with this, for any domain (eg:
www.foofoofoofoofoof.onion) the EOTK provides a fixed url:

* `https://www.foofoofoofoofoof.onion/hello-onion/`

...which (`/hello-onion/`) is internally served by the NGINX proxy and
provides a stable, fixed URL for SSL certificate acceptance; inside
TorBrowser another effective solution is to open all the broken links,
images and resources "in a new Tab" and accept the certificate there.

In production, of course, one would expect to use an SSL EV
certificate to provide identity and assurance to an onion site,
rendering these issues moot.

# Requirements

* `tor` 2.9.8 or later
  * ideally, the latest stable version
* `nginx`
  * with `ngx_http_sub_module`
    * https://nginx.org/en/docs/http/ngx_http_sub_module.html
  * with `headers_more`
    * https://www.nginx.com/resources/wiki/modules/headers_more/

# commands

* `eotk config [filename]` # default `onions.conf`
  * synonyms: `conf`, `configure`
* `eotk start projectname ...` # or: `-a` for all
* `eotk stop projectname ...` # or: `-a` for all
* `eotk bounce projectname ...` # or: `-a` for all
  * synonyms: `restart`, `reload`
* `eotk debugon projectname ...` # or: `-a` for all
* `eotk debugoff projectname ...` # or: `-a` for all
* `eotk harvest projectname ...` # or: `-a` for all
  * synonyms: `onions`
* `eotk status projectname ...` # or: `-a` for all

# Installation: OSX

Currently works on OSX with Homebrew:

* install homebrew - http://brew.sh/
* `git clone https://github.com/alecmuffett/eotk.git`
* `cd eotk`
* `sh ./000-setup-osx.sh` # installs required software; if you're worried, check it first
* `sh ./001-configure-demo.sh` # creates a working config file
* `./eotk config` # creates tor & onion configuration files; lists onion sites
  * (review your config file - `onion-tk.conf` for interest)
* `./eotk start default`
  * (connect to one of the onion sites cited in the `default` project)
  * (play SSL-Certificate-Whackamole)
  * (browse a little)
* `./eotk stop default`

# Installation: Debian/Raspbian/Ubuntu

Work in progress. Feedback welcome.


# I want to create a new project / my own configuration!

You can either add a new project to the demo config file, or you can
create a new config for yourself.

The simplest configuration file probably looks like this:

```
set project myproject
hardmap secrets.d/xxxxxxxxxxxxxxxx.key foo.com
```

...and if you create a file called `project.conf` containing those
lines, then you should be able to do:

```
./eotk configure project.conf
./eotk start myproject
```

## But how do I create my own "secrets.d/xxxxxxxxxxxxxxxx.key"?

```
cd secrets.d
./generate-onion-key.sh
```

Do this as many times as you wish/need.
