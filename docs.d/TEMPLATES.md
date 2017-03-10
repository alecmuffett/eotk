# EOTK Templates

The EOTK template engine is an enormous (but reasonably clean) kludge
for automating repetitive tasks in template-building; it started off
as a small Perl hack (because existing templaters really sucked, or
required YAML or other such nonsense) and then gret to add
functionality in a mostly-considered, mostly-orthogonal way.

For further examples, see also the unit tests in
`lib.d/test-expand-template.sh`.

## Variables

The templater reads/uses variables from three places:

* The Unix Process Environment (lowest priority)
* Space-separated columnar input from STDIN
* Local "Range" or builtin variables (highest priority)

Attempts to interpolate a nonexistent (rather than empty) variable
*anywhere* are a fatal error.

### Environment

A simple example of the first case:

```
$ echo $USER $SHELL TERM
alecm /bin/bash TERM

$ cat > foo.template
Hello %USER% using %SHELL% in %TERM%

$ ./lib.d/expand-template.pl foo.template </dev/null
Hello alecm using /bin/bash in xterm
```

### Columnar

The second (columnar) kind of data is read from stdin (hence the
`</dev/null` in the previous example; in a manner akin to a
spreadsheet, the templater reads a line containing a list of
space-separated column-names, and then further lines containing
space-separated column values.

Columnar variables are then applied between `%%BEGIN` and `%%END`
blocks:

```
$ cat foo.template
We learned that:
%%BEGIN
- %NAME% (age %AGE%) likes %SHELL%
%%END
...really

$ cat foo.input
NAME AGE
Alice 22
Bob 31
Charlotte 14

$ ./lib.d/expand-template.pl foo.template <foo.input
We learned that:
- Alice (age 22) likes /bin/bash
- Bob (age 31) likes /bin/bash
- Charlotte (age 14) likes /bin/bash
...really
```

There is no "escaping" mechanism for whitespace in column input, and
so far there has not actually needed to be one, but possibly the input
format may migrate in future to permit an additional CSV alternative.

### Local

Finally, there are builtin functions to provide primitive loop
constructs; there are `%%RANGE` and `%%CSV`:

```
$ cat foo.template
Let's count from 1 to 5!
%%RANGE I 1 5
* %I%
%%ENDRANGE

Also, we learned:
%%CSV alice,apples,dogs bob,carrots,cats %EXTRA_CSV_ENV%
* %1% likes %2%, but not %3%
%%ENDCSV
```
...which executes as:

```
$ env EXTRA_CSV_ENV=charlotte,coffee,tea ./lib.d/expand-template.pl foo.template </dev/null
Let's count from 1 to 5!
* 1
* 2
* 3
* 4
* 5

Also, we learned:
* alice likes apples, but not dogs
* bob likes carrots, but not cats
* charlotte likes coffee, but not tea
```

Environment (and other) Variables are interpolated into a `%%RANGE` or
`%%CSV` before being executed, as you can see from `EXTRA_CSV_ENV`,
above.

In `%%RANGE` loops the first argument `I` becomes the interpolatable
as `%I%`.

In `%%CSV` loops, the arguments `alice,apples,dogs` are automatically
split on commas to become numbered variables:

* `%0%` = `alice,apples,dogs`
* `%1%` = `alice`
* `%2%` = `apples`
* `%3%` = `dogs`

...and this parse/expansion is iterated over all arguments to the
`%CSV%` line.

## Control Statements

There are simple conditionals:

```
%%IF %BOOLEAN%
<text to be included if value of %BOOLEAN% evaluates to "true">
%%ENDIF

%%IF %BOOLEAN%
<text to be included if value of %BOOLEAN% evaluates to "true">
%%ELSE
<text to be included if value of %BOOLEAN% evaluates to "false">
%%ENDIF
```

...and simple conditional operations:

```
$ cat foo.template
%%IF %HOME% contains /Users/
you are probably on a Mac (%HOME%)
%%ELSE
you are probably NOT on a Mac (%HOME%)
%%ENDIF

$ ./lib.d/expand-template.pl foo.template </dev/null
you are probably on a Mac (/Users/alecm)
```

... **HOWEVER** these are intentionally implemented in an exceedingly
dangerous fashion, for maximum creative possibilities and laziness:

```
$ cat foo.template
%%IF %A% %COND% %B%
eval to true
%%ELSE
eval to false
%%ENDIF

$ env A=foo B=foo COND=eq ./lib.d/expand-template.pl foo.template </dev/null
eval to true

$ env A=foo B=foo COND=ne ./lib.d/expand-template.pl foo.template </dev/null
eval to false

$ env A=ohfooboo B=foo COND=contains ./lib.d/expand-template.pl foo.template </dev/null
eval to true
```

...but woe betide you if you introduce extra spaces or unset variables
into a comparison, because whitespace-splitting and parsing happens
**after** variable expansion:

```
$ env A='' B='' COND='TEAM !contains ME' ./lib.d/expand-template.pl foo.template </dev/null
eval to true
```

...and with debugging enabled, note the `if-expand` line:

```
$ env A='' B='' COND='TEAM !contains ME' ./lib.d/expand-template.pl --debug foo.template </dev/null
PrintBlock: begin at 0, end at 4
found %%IF at 0: %%IF %A% %COND% %B%
found %%ELSE at 2: %%ELSE
found %%ENDIF at 4: %%ENDIF
if-expand: %%IF  TEAM !contains ME
Evaluate TEAM !contains ME at ./lib.d/expand-template.pl line 16.
Evaluate2 TEAM at ./lib.d/expand-template.pl line 16.
Evaluate2 !contains at ./lib.d/expand-template.pl line 16.
Evaluate2 ME at ./lib.d/expand-template.pl line 16.
result: 1
print true block
PrintBlock: begin at 1, end at 1
Echo1 eval to true
Echo2 eval to true
eval to true
symbol dump:
A
B
COND
```

This is, after all, essentially a macro-processor and not a
programming language; this also reflects the importance of whitespace,
that `%%IF %I% < 6` is not the same as `%%IF %I%<6`; the latter is a
non-empty string which will always evaluate to `true`.

### Numeric Operators

eg: `%%IF %NUMDAEMONS% < 6`

* ==
* !=
* >=
* <=
* >
* <

### String Operators

eg: `%%IF %ONION% eq facebookcorewwwi`

* eq
* ne
* ge
* le
* gt
* lt
* contains
* !contains

Logic Operators

eg: `%%IF %BOOL1% and %BOOL2%` - no subexpressions, sorry

* and
* or
* xor

### Operator Notes

If you are at risk of empty strings for string comparisons,
disambiguate the string interpolation with quotes, thusly:

```
%%IF "%FOO%" eq "%BAR%"
```

...and please remember that the whole thing will explode messily (and
the logic will possibly change) if %FOO% contains a whitespace
character.

## Relevance to EOTK Config-File Format

Variables are set in a config file as:

```
set foo bar baz
```

This will result in the (uppercase) Environment Variable `FOO` being
set to the string `bar baz`, and then being available to the templater
as `%FOO%`.

Therefore it is entirely possible (though dangerous) to do this:

```
set path /usr/bin:/bin:...
```

...and set the `$PATH` environment variable for the rest of template
generation.  Doing so will probably break everything, so on your head
be it.

*IMPORTANT* - all variables, excepting `project`, are retroactively
global in scope; even if you set them at the **bottom** of a config
file, they impact the projects at the **top**. For clarity, keep all
globals at the top, and if you have projects which need different
settings then use different config files and different runs of `eotk
configure`.

# Variable Index

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

* BLOCK_HOST (none)
* BLOCK_HOST_RE (none)
* BLOCK_LOCATION (none)
* BLOCK_LOCATION_RE (none)
* NGINX_CACHE_SECONDS (0)
* NGINX_CACHE_SIZE (16m)
* NGINX_HELLO_ONION (on)
* NGINX_RESOLVER (8.8.8.8)
* NGINX_RESOLVER_FLAGS
* NGINX_RLIM (1024)
* NGINX_SYSLOG (error)
* NGINX_TIMEOUT (30 seconds)
* NGINX_WORKERS (auto)
* SOFTMAP_NGINX_WORKERS (auto)
* SUPPRESS_HEADER_CSP (on)
* SUPPRESS_HEADER_HPKP (on)
* SUPPRESS_HEADER_HSTS (on)
* SUPPRESS_METHODS_EXCEPT_GET (off)

### Tor Configuration

* TOR_DIR :boom: :no_entry:
* TOR_INTROS_PER_DAEMON (3)
* TOR_SINGLE_ONION (on)
* TOR_SYSLOG (notice)
* TOR_WORKER_PREFIX ("hs")
* SOFTMAP_TOR_WORKERS (2)

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
