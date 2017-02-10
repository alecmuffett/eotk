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

### EOTK Configuration

#### Documentation TBD

* PROJECTS_HOME
* PROJECT :boom:
* PROJECT_DIR :boom:
* LOG_DIR :boom:
* SSL_DIR :boom:
* CERT_PREFIX

### EOTK Use

#### Documentation TBD

* IS_SOFTMAP :boom: :no_entry:
* SCRIPT_PAUSE
* SCRIPT_NAMES :no_entry:
* SSL_TOOL
* TEMPLATE_TOOL


### NGINX Configuration

#### NGINX_HELLO_ONION

Creates a "/hello-onion/" URL on all onion domains/subdomains; this
provides a helpful fixed point when prototyping to navigate to for
accepting self-signed SSL certificates, etc. Use `0` to switch
off. Underscore also accepted.

#### Documentation TBD

* HEADER_CSP_SUPPRESS
* HEADER_HSTS_SUPPRESS
* NGINX_RESOLVER
* NGINX_RLIM
* NGINX_TIMEOUT
* NGINX_WORKERS
* SOFTMAP_NGINX_WORKERS

### Tor Configuration

#### Documentation TBD

* TOR_DIR :boom: :no_entry:
* TOR_INTROS_PER_DAEMON
* TOR_SINGLE_ONION
* TOR_WORKER_PREFIX
* SOFTMAP_TOR_WORKERS

## Begin/End Variables

#### Documentation TBD

* DNS_DOMAIN
* DNS_DOMAIN_RE
* ONION_ADDRESS
* ONION_ADDRESS_RE
* KEYFILE

## Fake Variables

#### NEW_ONION

Used only in template configs (`*.tconf` files) to show the point
where a newly created onion keyfile path should be inserted.

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

Also you can nest RANGE and IF/ELSE/ENDIF in obvious ways, within a
BEGIN/END body

There is currently a fatal block on empty IF or ELSE template bodies.

The overall concept is to make a template which is easy to portably
generate/regenerate, containing lots of hard-codeables for simplicity.
