# The Enterprise Onion Toolkit
## eotk (c) 2017 Alec Muffett


# Status

The code is currently pre-alpha - too hacky for words.  It will improve.

The goal is to provide a tool for prototyping, and eventually
deploying at scale, HTTP and HTTPS onion sites to provide official
presence for popular websites.

The results are certainly impactful upon security, pose all manner of
risk; set them up only for your own sites or for sites which do not
require login credentials of any kind.


# Usage Notes

When using the resulting onions over HTTP/SSL, you will be using
wildcard self-signed SSL certificates - you *will* encounter many
"broken links" which are due to the SSL certificate not being valid.

This is expected and proper behaviour.

For any domain (eg: www.foofoofoofoofoof.onion) the EOTK provides a
fixed url:

* `https://www.foofoofoofoofoof.onion/hello-onion/`

...which is internally served by the NGINX proxy and provides a fixed
point for SSL certificate acceptance; inside TorBrowser another
effective solution is to open all the broken links, images and
resources "in a new Tab" and accept the certificate there.

In production, of course, one would expect to use an SSL EV
certificate to provide identity and assurance to an onion site.


# Requirements

* `tor` 2.9.8 or later (ideally: latest)
* `nginx`
  * with `ngx_http_sub_module`
    https://nginx.org/en/docs/http/ngx_http_sub_module.html
  * with `headers_more`
    * https://www.nginx.com/resources/wiki/modules/headers_more/
* a local DNS resolver
  * e.g.: `dnsmasq`


# Installation: OSX

Currently works on OSX with Homebrew:

* install homebrew - http://brew.sh/
* `git clone https://github.com/alecmuffett/eotk.git`
* `cd eotk`
* `sh ./000-setup-osx.sh` # installs required software; if you're worried, check it first
* `sh ./001-configure-demo.sh` # creates a working config file
* `sh ./onion-tk.sh config` # creates tor & onion configuration files; lists onion sites
* (review your config file - `onion-tk.conf` for interest)
* `./projects.d/default.d/start.sh`
* (connect to one of the onion sites cited in the `default` project)
* (play SSL-Certificate-Whackamole)
* (browse a little)
* `./projects.d/default.d/stop.sh` # to stop the `default` project


# Installation: Debian/Raspbian/Ubuntu

Work in progress. Feedback welcome.
