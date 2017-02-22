#!/usr/bin/perl
# eotk (c) 2017 Alec Muffett

my %known =
    (
     'SSL_TOOL' => 1,
     'TEMPLATE_TOOL' => 1,

     # dns source domains
     'DNS_DOMAIN' => 1, # site being mapped
     'DNS_DOMAIN_RE' => 1, # ...with dots escaped
     'DNS_DOMAIN_RE2' => 1, # ...with dots double-escaped

     # onion destination addresses
     'ONION_ADDRESS' => 1, # onion being mapped-to
     'ONION_ADDRESS_RE' => 1, # with dots escaped
     'ONION_ADDRESS_RE2' => 1, # with dots double-escaped

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
     'HEADER_CSP_SUPPRESS' => 1,
     'HEADER_HPKP_SUPPRESS' => 1,
     'HEADER_HSTS_SUPPRESS' => 1,
     'IS_SOFTMAP' => 1,
     'NGINX_HELLO_ONION' => 1,
     'NGINX_RESOLVER' => 1,
     'NGINX_RLIM' => 1,
     'NGINX_SYSLOG' => 1,
     'NGINX_TEMPLATE' => 1,
     'NGINX_TIMEOUT' => 1,
     'NGINX_WORKERS' => 1,
     'SOFTMAP_NGINX_WORKERS' => 1,
     'SOFTMAP_TOR_WORKERS' => 1,
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

while (<>) { s/%(\w+)%/$syms{$1}++, '-'/ge; }

foreach $var (sort keys %syms) {
    print "$syms{$var} $var";
    print " <- *unknown*" unless ($known{$var});
    print "\n";
}

exit 0;
