# Quick Start For Experimentation

## Step 1: install EOTK and build the necessary executables

See [the instructions](HOW-TO-INSTALL.md).

## Step 2: create a template-config file

Create a file named `myproject.tconf` that contains:
```
# boilerplate, adjust if needed
set nginx_resolver 8.8.8.8 1.1.1.1 ipv6=off
set nginx_cache_seconds 60
set nginx_cache_size 64m
set nginx_tmpfile_size 8m
set log_separate 1

# preserve this domain name in free text or email addresses
set preserve_csv save,mydomain\\.com,i,mydomain.com

set project myproject
hardmap %NEW_V3_ONION% mydomain.com
```

...and amend the values of `mydomain` and `com`
(if you are not using a `.com` top level domain)
throughout that file.

## Step 3: generate an actual configuration

Run:
```
eotk config myproject.tconf
```
...which will create `myproject.conf` and populate it with onion addresses.

## Step 4: generate startup scripts

Run:
```
eotk script
```
...which will generate start-on-boot and cronjob-housekeeping scripts; read them for installation instructions.

## Step 5: start your server

Run:
```
eotk start myproject
```
...to start your server; then do:
```
eotk maps myproject
```
...to see what onion address to connect to.
