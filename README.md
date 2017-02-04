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

# User Manual

Intuitively obvious to the most casual observer:

* `eotk config [filename]` # default `onions.conf`
  * *synonyms:* `conf`, `configure`
  * parses the config file and sets up and populates the projects
* `eotk status projectname ...` # or: `-a` for all
  * process status
* `eotk maps projectname ...` # or: `-a` for all
  * print which onions correspond to which dns domains
* `eotk start projectname ...` # or: `-a` for all
  * start projects
* `eotk stop projectname ...` # or: `-a` for all
  * stop projects
* `eotk bounce projectname ...` # or: `-a` for all
  * *synonyms:* `restart`, `reload`
  * stop, and restart, projects
* `eotk debugon projectname ...` # or: `-a` for all
  * enable verbose tor logs
* `eotk debugoff projectname ...` # or: `-a` for all
  * disable verbose tor logs
* `eotk harvest projectname ...` # or: `-a` for all
  * *synonyms:* `onions`
  * print list of onions used by projects

# Installation: OSX

Currently works on OSX with Homebrew:

* install homebrew - http://brew.sh/
* `git clone https://github.com/alecmuffett/eotk.git`
* `cd eotk`
* `sh ./000-setup-osx.sh` # installs required software; if you're worried, check it first

# Installation: Debian/Raspbian/Ubuntu

Work in progress. Feedback welcome.

# I want to experiment!

If you want to experiment with some prefabricated projects, try this:

* `sh ./001-configure-demo.sh` # creates a working config file, `demo.conf`
* `eotk config demo.conf` # creates tor & nginx config files; lists onion sites
* `eotk start default`
* Now you can...
  * Connect to one of the onions cited on screen for the `default` project
  * Play SSL-Certificate-Acceptance-Whackamole
  * Browse a little...
* `eotk stop default`

# I want to create a new project / my own configuration!

You can either add a new project to the demo config file, or you can
create a new config for yourself.  If you want an onion for `foo.com`,
the simplest configuration file probably looks like this:

```
set project myproject
hardmap secrets.d/xxxxxxxxxxxxxxxx.key foo.com
```

...and if you create a file called `project.conf` containing those
lines, then you should be able to do:

```
eotk configure project.conf
eotk start myproject
```

## But how do I create my own "secrets.d/xxxxxxxxxxxxxxxx.key"?

```
cd secrets.d
./generate-onion-key.sh
```

Do this as many times as you wish/need.
