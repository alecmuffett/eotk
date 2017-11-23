#!/usr/bin/perl
# eotk (c) 2017 Alec Muffett

my %known =
    (
     '' => 1, # an empty escape character
     'X_FROM_ONION_VALUE' => 1,

     'SSL_TOOL' => 1,
     'TEMPLATE_TOOL' => 1,

     # expect to de-onionify onions in request paths
     'PATHS_CONTAIN_ONIONS' => 1,

     # hardcoded endpoints for proofs
     'HARDCODED_ENDPOINT_CSV' => 1,

     # basic access control
     'COOKIE_LOCK' => 1,

     # hard-mode preservation
     'PRESERVE_COOKIE' => 1,
     'PRESERVE_CSV' => 1,
     'PRESERVE_PREAMBLE' => 1,

     # dns source domains
     'DNS_DOMAIN' => 1, # site being mapped
     'DNS_DOMAIN_RE' => 1, # ...with dots escaped
     'DNS_DOMAIN_RE2' => 1, # ...with dots double-escaped
     'DNS_DOMAIN_RERE' => 1, # ...with dots escaped
     'DNS_DOMAIN_RERE2' => 1, # ...with dots double-escaped

     # onion destination addresses
     'ONION_ADDRESS' => 1, # onion being mapped-to
     'ONION_ADDRESS_RE' => 1, # with dots escaped
     'ONION_ADDRESS_RE2' => 1, # with dots double-escaped
     'ONION_ADDRESS_RERE' => 1, # with dots escaped
     'ONION_ADDRESS_RERE2' => 1, # with dots double-escaped

     # ssl cert prefix
     'CERT_PREFIX' => 1,

     # template directories
     'LOG_DIR' => 1, # where logs for the current project live
     'SSL_DIR' => 1, # where ssl certs for the current project live
     'TOR_DIR' => 1, # where the current onion is being installed; subtle
     'PROJECT' => 1, # what the current project is called
     'PROJECT_DIR' => 1, # where the current project is being installed
     'PROJECTS_HOME' => 1, # where the projects live

     # in-template settings
     'BLOCK_ERR' => 1,
     'BLOCK_HOST' => 1,
     'BLOCK_HOST_RE' => 1,
     'BLOCK_LOCATION' => 1,
     'BLOCK_LOCATION_RE' => 1,
     'DEBUG_TRAP' => 1,
     'EXTRA_PROCESSING_CSV' => 1,
     'FORCE_HTTPS' => 1,
     'FOREIGNMAP_CSV' => 1,
     'IS_SOFTMAP' => 1,
     'NGINX_BLOCK_BUSY_SIZE' => 1,
     'NGINX_BLOCK_COUNT' => 1,
     'NGINX_BLOCK_SIZE' => 1,
     'NGINX_CACHE_MIN_USES' => 1,
     'NGINX_CACHE_SECONDS' => 1,
     'NGINX_CACHE_SIZE' => 1,
     'NGINX_HASH_BUCKET_SIZE' => 1,
     'NGINX_HELLO_ONION' => 1,
     'NGINX_RESOLVER' => 1,
     'NGINX_RESOLVER_FLAGS' => 1,
     'NGINX_RLIM' => 1,
     'NGINX_SYSLOG' => 1,
     'NGINX_TEMPLATE' => 1,
     'NGINX_TIMEOUT' => 1,
     'NGINX_TMPFILE_SIZE' => 1,
     'NGINX_WORKERS' => 1,
     'NO_CACHE_CONTENT_TYPE' => 1,
     'NO_CACHE_HOST' => 1,
     'REDIRECT_HOST_CSV' => 1,
     'REDIRECT_LOCATION_CSV' => 1,
     'SOFTMAP_NGINX_WORKERS' => 1,
     'SOFTMAP_TOR_WORKERS' => 1,
     'SUPPRESS_HEADER_CSP' => 1,
     'SUPPRESS_HEADER_HPKP' => 1,
     'SUPPRESS_HEADER_HSTS' => 1,
     'SUPPRESS_METHODS_EXCEPT_GET' => 1,
     'SUPPRESS_TOR2WEB' => 1,
     'TOR_INTROS_PER_DAEMON' => 1,
     'TOR_SINGLE_ONION' => 1,
     'TOR_SYSLOG' => 1,
     'TOR_TEMPLATE' => 1,
     'TOR_WORKER_PREFIX' => 1,

     # demo fakes
     'NEW_ONION' => 1,
     'NEW_HARD_ONION' => 1,
     'NEW_SOFT_ONION' => 1,

     # in the control scripts
     'SCRIPT_PAUSE' => 1,
    );

my %syms = ();

while (<>) { s/%(\w*)%/$syms{$1}++, '-'/ge; }

foreach $var (sort keys %syms) {
    print "$syms{$var} $var";
    print " <- *unknown*" unless ($known{$var});
    print "\n";
}

exit 0;
