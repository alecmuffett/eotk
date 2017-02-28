# EOTK Tuneables

These are the values which are set in a config file as:

```
set variable_name variable value
```

...where `variable value` is a verbatim string that will be inserted
into the resulting output, no quoting required or supported - though
multiple whitespace will be squashed/lost into single spaces, and
trailing whitespace is stripped.

The resulting value can be inserted into templates using:

```
%VARIABLE_NAME%
```

Variables are inherited from the global set of environment variables
(ie: `%USER%` and `%PATH%` are already set, etc) - but may be locally
or temporarily overridden.

*IMPORTANT* - all variables, excepting `project`, are retroactively
global in scope; if you set them at the bottom of a config file, they
impact the projects at the top. For clarity, keep them at the top, and
if you have projects which need different settings, use different
config files and different runs of `eotk configure`.

# Variables

Key:

* defaulted per project = :boom:
* not settable / do not change = :no_entry:

## Global Variables

Defaults in (parentheses)

### EOTK Configuration

* PROJECTS_HOME (projects.d)
* PROJECT :boom:
* PROJECT_DIR (PROJECTS_HOME/projname.d) :boom:
* LOG_DIR (PROJECT_DIR/log.d) :boom:
* SSL_DIR (PROJECT_DIR/ssl.d) :boom:

### Template Generation

* TEMPLATE_TOOL (lib.d/expand-template.pl)
* NGINX_TEMPLATE (templates.d/nginx.conf.txt)
* TOR_TEMPLATE (templates.d/tor.conf.txt)

### SSL Certificate Generation

* SSL_TOOL (lib.d/make-selfsigned-wildcard-ssl-cert.sh)
* CERT_COMMON_NAME (not set, use to override CERT_PREFIX)
* CERT_PREFIX (first onion address cited in project)

### EOTK Operation

* IS_SOFTMAP :boom: :no_entry:
* SCRIPT_PAUSE (5 seconds)
* SCRIPT_NAMES :no_entry:

### NGINX Configuration

* NGINX_HELLO_ONION (on)
* NGINX_RESOLVER (8.8.8.8)
* NGINX_RESOLVER_FLAGS
* NGINX_RLIM (1024)
* NGINX_SYSLOG (error)
* NGINX_TIMEOUT (30 seconds)
* NGINX_WORKERS (5)
* SOFTMAP_NGINX_WORKERS (20)
* SUPPRESS_HEADER_CSP (on)
* SUPPRESS_HEADER_HPKP (on)
* SUPPRESS_HEADER_HSTS (on)

### Tor Configuration

* TOR_DIR :boom: :no_entry:
* TOR_INTROS_PER_DAEMON (3)
* TOR_SINGLE_ONION (on)
* TOR_SYSLOG (notice)
* TOR_WORKER_PREFIX ("hs")
* SOFTMAP_TOR_WORKERS (4)

## Begin/End Variables

* DNS_DOMAIN
* DNS_DOMAIN_RE (backslashed dots)
* DNS_DOMAIN_RE2 (double-backslashed dots)
* ONION_ADDRESS
* ONION_ADDRESS_RE (backslashed dots)
* ONION_ADDRESS_RE2 (double-backslashed dots)
* KEYFILE :no_entry: (cited in config)

## Fake Variables

* NEW_ONION / NEW_HARD_ONION
* NEW_SOFT_ONION

Used only in template configs (`*.tconf` files) to show the point where
a newly created onion and/or keyfile path should be inserted.

# Template Syntax

There are technical examples in `lib.d/test-expand-template.sh` but
broadly the syntax is:

## Control Statements

```
%%IF %BOOLEAN%
<text to be included if value of "set boolean" is non-zero>
%%ENDIF

%%IF %BOOLEAN%
<text to be included if value of "set boolean" is non-zero>
%%ELSE
<text to be included if value of "set boolean" is zero>
%%ENDIF
```

## Integer Ranges

set j 4
set k 5
```
%%RANGE I 0 2
foo %I%
%%ENDRANGE
%%RANGE I %J% %K%
bar %I%
%%ENDRANGE
```

...will result in:

```
foo 0
foo 1
foo 2
bar 4
bar 5
```

## BEGIN/END

The template engine expects to read a document from standard input, of
the example form:

```
FOO BAR BAZ
1 2 3
a b c
x y z
```

...and a template like this:

```
%%BEGIN
data: %FOO% %BAR% %BAZ%
%%END
```

...will yield output:

```
data: 1 2 3
data: a b c
data: x y z
```

However, they are also nestable (cross-product) so you can do this:

```
%%BEGIN
title: %FOO%
  %%BEGIN
  body: %BAR% %BAZ%
  %%END
%%END
```

...which should yield:

```
title: 1
  body 2 3
  body b c
  body y z
title: a
  body 2 3
  body b c
  body y z
title: x
  body 2 3
  body b c
  body y z
```

* you can nest RANGE and IF/ELSE/ENDIF in obvious ways, within a
  BEGIN/END body
* The goal is to make a template which is easy to portably generate
  and regenerate, containing lots of hard-codeables for simplicity.
