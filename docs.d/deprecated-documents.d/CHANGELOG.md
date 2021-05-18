# Changelog

## HEAD (to become v1.5)
* new features
* `eotk-site.conf`
  * "global" configuration rules to prefix into every configuration
  * auto-created it if it does not exist
  * used it to solve NGINX installation on Ubuntu 18.04LTS
* OnionBalance to be deprecated until overhauled by Tor
  * see notes in [HOW-TO-INSTALL.md](HOW-TO-INSTALL.md)
* Ubuntu 18.04LTS becomes mainline for Ubuntu
  * Ubuntu 16.04LTS becomes deprecated
* Support for v3 Onion Addresses
  * use `%NEW_V3_ONION%` in template configs (`.tconf`) to autogenerate
  * see `demo.d/wikipedia-v3.tconf` for examples

## v1.4
* new features
  * auto-generate (`eotk make-scripts`) wrapper scripts for:
    * installation into "init" startup `eotk-init.sh`
    * log rotation / housekeeping via installation into eotk-user cronjob (`eotk-housekeeping.sh`)
  * stricter enforcement of onionification
    * by default will drop compressed, non-onionifiable content with error code `520`
    * if this is a problem (why?) use `set drop_unrewritable_content 0` to disable
  * validate worker onion addresses upon creation
    * works around [issue logged with tor](https://trac.torproject.org/projects/tor/ticket/29429)
  * `eotk spotpush` now permits pushing explicitly named scripts from `$EOTK_HOME`, as well as hunting in `projects.d`
  * `set hard_mode 1` is now **default** and onionifies both `foo.com` AND `foo\.com` (regexp-style)
    * use `set hard_mode 2` to further onionify `foo\\.com` and `foo\\\.com` at slight performance cost
  * `set ssl_mkcert 1` to use [mkcert](https://github.com/FiloSottile/mkcert) by @FiloSottile for certificate generation, if you have installed it
  * refactor nonces used in rewriting preserved strings
  * improvements to `set debug_trap pattern [...]` logging
  * support for OpenResty LuaJIT in Raspbian build scripts
  * update code version for Raspbian builds scripts
  * tor HiddenServiceVersion nits
  * dead code removal
  * deprecate support for Raspbian Jessie

## v1.3
* new features
  * "Runbook" has been [moved to the documentation directory](docs.d/RUNBOOK.md)
  * tor2web has been blocked-by-default
    * since the reason for EOTK is to provide Clearnet websites with an Onion presence, Tor2web is not necessary
  * the `FORCE_HTTPS` feature has been added and made *default*
    * if your site is 100% HTTPS then you do not need to do anything,
    * however sites which require insecure `HTTP` may have to use `set force_https 0` in configurations.

## v1.2
* new features:
  * optional blocks to methods other than GET/HEAD
  * optional 403/Forbidden blocks for accesses to certain Locations or Hosts, including as regexps
    * nb: all blocks/block-patterns are *global* and apply to all servers in a project
  * optional time-based caching of static content for `N` seconds, with selectable cache size (def: 16Mb)
* new [How To Install](docs.d/HOW-TO-INSTALL.md) guide
* custom install process for Ubuntu, tested on Ubuntu Server 16.04.2-LTS
* renaming / factor-out of Raspbian install code
* fixes to onionbalance support

## v1.1
* first cut of onionbalance / softmap

## v1.0
* have declared a stable alpha release
* architecture images, at bottom of this page
* all of CSP, HSTS and HPKP are suppressed by default; onion networking mitigates much of this
* ["tunables"](docs.d/TEMPLATES.md) documentation for template content
* `troubleshooting` section near the bottom of this page
* See [project activity](https://github.com/alecmuffett/eotk/graphs/commit-activity) for information
