#!/usr/bin/perl -w
# eotk (c) 2017 Alec Muffett

use Data::Dumper;

die "$0: needs EOTK_HOME environment variable to be set\n"
    unless (defined($ENV{EOTK_HOME}));

# state

my %projects = ();
my %foreign_by_domain = ();
my %foreign_by_onion = ();
my $unset_variable = "<-UNSET-VARIABLE->";
my $here = $ENV{EOTK_HOME};

chdir($here) or die "chdir: $here: $!\n";

##################################################################

sub JoinLines {
    my @input = @_;
    my @output = ();
    my $append_next = 0;
    foreach my $line (@input) {
        # are we left in a cached state?
        if ($append_next) {
            my $prev = pop(@output);
            $prev =~ s!\s+$!!;
            $line =~ s!^\s+!!;
            $line = $prev . " " . $line;
            $append_next = 0;
            # fallthru
        }

        # no trailing slashes -> push
        if ($line !~ m!(\\+)$!o) {
            $append_next = 0;
            push(@output, $line);
            next;
        }

        # trailing \\ or \\\\ ... -> push
        if ((length($1) % 2) == 0) {
            $append_next = 0;
            push(@output, $line);
            next;
        }

        # remove trailing \, mark for append, and push
        die "failure to remove trailing slash" unless ($line =~ s!\\$!!o);
        push(@output, $line);
        $append_next = 1;
    }
    die "error: hanging backslash at end of input\n" if ($append_next);
    return @output;
}

sub SetEnv {
    my ($var, $val, $why) = @_;
    die "bad varname: $var\n" if ($var !~ /^[A-Za-z_]\w+/);
    $var =~ tr/a-z/A-Z/;

    if (!defined($why)) {
        $why = ''; # stop warnings about uninitialised strings
    }

    if ($why eq 'config-file') {
        print "warning: $var is not an existing EOTK or environment variable; possible typo?\n"
            if !exists($ENV{$var});
    }

    if (defined($ENV{$var}) and ($ENV{$var} ne "")) {
        warn "WARNING: setting $var overwrites existing '$ENV{$var}' with '$val'\n";
    }

    $ENV{$var} = $val;
    warn (($why ? "($why) " : "") . "set $var to $val\n");
}

sub RunOrDie {
    warn "RunOrDie @_\n";
    (system(@_) == 0) or die "system: @_: $!\n";
}

sub GoAndRun {
    warn "GoAndRun @_\n";
    my ($where, @cmd) = @_;
    chdir($where) or die "chdir: $where: $!\n";
    &RunOrDie(@cmd);
    chdir($here) or die "chdir: $here: $!\n";
}

sub Pipeify {
    my ($cmd, @hashreflist) = @_; # there WILL be shell syntax in $cmd
    warn "Pipeify $cmd ...\n";

    my $first = $hashreflist[0];

    if (!defined($first)) {
        warn "Pipeify note: empty template\n";
    }

    my @vars = sort keys %{$first}; # get column names, assume uniformity

    open(PIPE, "|$cmd") or die "popen: $cmd: $!\n";
    warn "head @vars\n";
    print PIPE join(" ", @vars), "\n"; # send the column names, even if "empty"

    foreach my $hashref (@hashreflist) { # send the rows
        my @row = ();
        foreach my $var (@vars) {
            my $val = ${$hashref}{$var};
            die "Pipeify: empty var $var\n" unless ($val ne "");
            die "Pipeify: whitespace var $var: $val\n" if ($val =~ /\s/);
            push(@row, $val);
        }
        warn "body @row\n";
        print PIPE join(" ", @row), "\n";
    }
    close(PIPE) or die "pclose: $cmd: $!\n";
}

sub MakeDir {
    warn "MakeDir @_\n";
    my $path = shift;
    die "MakeDir: empty path?\n" unless ($path);
    if (! -d $path) {
        &RunOrDie("mkdir", "-p", $path);
    }
    chmod(0700, $path) or die "chmod: $path: $!\n";
}

sub CopyFile {
    warn "CopyFile: @_\n";
    my ($from, $to) = @_;
    &RunOrDie("cp", $from, $to);
    chmod(0600, $to) or die "chmod: $to: $!\n";
}

sub SlashDot { # dotify a regexp
    warn "SlashDot @_\n";
    my $arg = shift;
    $arg =~ s!\.!\\.!g;
    return $arg;
}

##################################################################

sub DoForeign {
    warn "DoForeign @_\n";
    my ($what, $onion, $domain, @crap) = @_;
    $onion =~ s!\.(onion)!!; # cleanup dups
    $onion = "$onion.onion"; # restore trailing .onion
    die "DoForeign: wtf?\n" if ($what ne "foreignmap");
    die "DoForeign: duplicate onion $onion\n" if ($foreign_by_onion{$onion});
    die "DoForeign: duplicate domain $domain\n" if ($foreign_by_domain{$domain});
    $foreign_by_onion{$onion} = $domain;
    $foreign_by_domain{$domain} = $onion;
}

##################################################################

# $projects{$project}{ROWS} = [ {}, {}, ... ] # see $row
# $projects{$project}{SUBDOMAINS} = {} # keys-only
# $projects{$project}{FIRST_ONION} = ""
# $projects{$project}{TYPE} = ""
# $projects{$project}{IS_SOFTMAP} = 0/1

# each $row = {
# DNS_DOMAIN
# DNS_DOMAIN_RE
# ONION_ADDRESS
# ONION_ADDRESS_RE
# KEYFILE
# }

# also, calling the templater will dynamically set:
# PROJECT
# PROJECT_DIR

sub DoMap {
    warn "DoMap @_\n";
    my ($what, $from, $to, @subdomains) = @_;
    my $ptype;

    my $project = $ENV{PROJECT}; # the instantaneous value of `project` is stored

    if (!defined($projects{$project})) {
        $projects{$project} = {};
    }

    if (!defined($projects{$project}{TYPE})) {
        $projects{$project}{TYPE} = $what;
        $projects{$project}{IS_SOFTMAP} = ($what eq "softmap" ? 1 : 0);
    }

    $ptype = $projects{$project}{TYPE};
    if ($ptype ne $what) {
        die "DoMap: you cannot add $what ($from/$to) to an existing $ptype project\n";
    }

    my $keyfile = $unset_variable;
    my $onion;

    if ($what eq "hardmap") {
        $keyfile = $from;
        die "map: $keyfile: no such file\n" unless -f ($keyfile);
        $onion = $keyfile;
        $onion =~ s!^.*/!!;
        $onion =~ s!\.(key|pem)!!;
        $onion =~ s!\.(onion)!!; # cleanup dups
    }
    elsif ($what eq "softmap") {
        $onion = $from;
        $onion =~ s!\.(onion)!!; # cleanup dups
        die "map: $onion: bad onion address\n" unless ($onion =~ /^[a-z2-7]{16}$/);
    }
    else {
        die "wtf?\n";
    }
    $onion = "$onion.onion"; # restore trailing .onion

    warn "$ptype $what($keyfile) from=$onion to=$to san=(@subdomains)\n";

    if (!defined($projects{$project}{FIRST_ONION})) {
        $projects{$project}{FIRST_ONION} = $onion;
    }

    # populate the subdomains
    $projects{$project}{SUBDOMAINS}{$onion} = 1;
    foreach my $sd (@subdomains) {
        $projects{$project}{SUBDOMAINS}{"$sd.$onion"} = 1;
    }

    # create the row
    my %row = ();
    my $x = $to;
    $row{DNS_DOMAIN} = $x; # foo.com
    $x = &SlashDot($x);
    $row{DNS_DOMAIN_RE} = $x; # foo\.com - static
    $x =~ s!\\!\\\\!g;
    $row{DNS_DOMAIN_RE2} = $x; # foo\\.com -- double-escaped
    $x = &SlashDot($x);
    $row{DNS_DOMAIN_RERE} = $x; # foo\\\.com - re static
    $x =~ s!\\!\\\\!g;
    $row{DNS_DOMAIN_RERE2} = $x; # foo\\\\\\.com -- double-escaped

    $x = $onion;
    $row{ONION_ADDRESS} = $x; # foo.onion
    $x = &SlashDot($x);
    $row{ONION_ADDRESS_RE} = $x; # foo\.onion
    $x =~ s!\\!\\\\!g;
    $row{ONION_ADDRESS_RE2} = $x; # foo\\.onion
    $x = &SlashDot($x);
    $row{ONION_ADDRESS_RERE} = $x; # foo\\\.onion
    $x =~ s!\\!\\\\!g;
    $row{ONION_ADDRESS_RERE2} = $x; # foo\\\\\\.onion

    $row{KEYFILE} = $keyfile;

    warn Dumper(\%row);

    # push a reference to the row
    push(@{$projects{$project}{ROWS}}, \%row);
}

##################################################################

sub DoProject {
    warn "DoProject @_\n";
    my $project = shift;

    # set the ephemerals
    &SetEnv("project", $project, "defaulting");
    &SetEnv("project_dir", "$ENV{PROJECTS_HOME}/$ENV{PROJECT}.d", "defaulting");
    &SetEnv("log_dir", "$ENV{PROJECT_DIR}/log.d", "defaulting");
    &SetEnv("ssl_dir", "$ENV{PROJECT_DIR}/ssl.d", "defaulting");
    &SetEnv("is_softmap", $projects{$project}{IS_SOFTMAP}, "inheriting");
    # tor_dir is a very special ephemeral, just for softmap, more later

    # make the directories
    &MakeDir($ENV{PROJECT_DIR});
    &MakeDir($ENV{SSL_DIR});
    &MakeDir($ENV{LOG_DIR});

    # set the CommonName for the project cert; this is the first onion encountered:
    my $cert_prefix;

    if (defined($ENV{CERT_COMMON_NAME})) {
        $cert_prefix = $ENV{CERT_COMMON_NAME};
    }
    else {
        if ($ENV{IS_SOFTMAP}) {
            $cert_prefix = "$project.local";
        }
        else {
            $cert_prefix = $projects{$project}{FIRST_ONION};
        }
    }
    die "empty cert_prefix in project $project\n" unless (defined($cert_prefix));
    &SetEnv("cert_prefix", $cert_prefix);

    # clean up the SAN list; purge the CommonName for deduplication
    delete($projects{$project}{SUBDOMAINS}{$cert_prefix});
    my @sanlist = sort keys %{$projects{$project}{SUBDOMAINS}};

    # debugging
    warn "commit $ENV{PROJECT} san $cert_prefix @sanlist\n";

    # cert generation
    $cert = "$ENV{SSL_DIR}/$cert_prefix.cert";
    if (-f $cert) {
        warn "$cert exists!";
    }
    else {
        warn "making cert for $cert_prefix\n";
        &GoAndRun(
            $ENV{SSL_DIR},
            $ENV{SSL_TOOL},
            $cert_prefix,        # must be first argument
            @sanlist
            );
    }

    # nginx config: feed the rows to the template
    my $cmd = "$ENV{TEMPLATE_TOOL} $ENV{NGINX_TEMPLATE} >$ENV{PROJECT_DIR}/nginx.conf";
    &Pipeify($cmd, @{$projects{$project}{ROWS}});

    # tor directory generation; we may nuke LOG_DIR in the process
    if ($ENV{IS_SOFTMAP}) {
        # for each enumerated worker
        foreach my $i (1..$ENV{SOFTMAP_TOR_WORKERS}) {
            # make worker directory
            my $hs_dir = "$ENV{PROJECT_DIR}/$ENV{TOR_WORKER_PREFIX}-$i.d";
            &MakeDir($hs_dir);

            # no keys to install, no poisoning to deal with

            # tor config using TOR_DIR to drop everything in there
            &SetEnv("tor_dir", $hs_dir, "softmap");
            my $cmd = "$ENV{TEMPLATE_TOOL} $ENV{TOR_TEMPLATE} >$hs_dir/tor.conf";
            &Pipeify($cmd, @{$projects{$project}{ROWS}});
        }

        # mark project as softmap; care with use of this information,
        # because workers will treat softmap projects as-if simply
        # "local" and pseudo-hardmap; use this information only for
        # filtering onionbalance management.
        &CopyFile("/dev/null", "$ENV{PROJECT_DIR}/softmap.conf");
    }
    else {
        # setup tor hs directories and keys
        foreach my $row (@{$projects{$project}{ROWS}}) {
            # what dns?
            my $dns = ${$row}{DNS_DOMAIN};

            # which onion?
            my $onion = ${$row}{ONION_ADDRESS};

            # make hs directory
            my $hs_dir = "$ENV{PROJECT_DIR}/$onion.d";
            &MakeDir($hs_dir);

            # install keyfile
            my $keyfile = ${$row}{KEYFILE};
            &CopyFile($keyfile, "$hs_dir/private_key");

            # bypass key-poisoning obscurity hassle
            $poison = "$hs_dir/onion_service_non_anonymous";
            if ($ENV{TOR_SINGLE_ONION}) {
                &CopyFile("/dev/null", $poison) if (! -f $poison);
            }
            else {
                unlink($poison) if (-f $poison);
            }
        }

        # tor config
        my $cmd = "$ENV{TEMPLATE_TOOL} $ENV{TOR_TEMPLATE} >$ENV{PROJECT_DIR}/tor.conf";
        &Pipeify($cmd, @{$projects{$project}{ROWS}});
    }

    # various scripts
    foreach my $script (split(" ", $ENV{SCRIPT_NAMES})) {
        my $path = "$ENV{PROJECT_DIR}/$script";
        my $cmd = "$ENV{TEMPLATE_TOOL} templates.d/$script.txt >$path";
        &Pipeify($cmd, @{$projects{$project}{ROWS}});
        chmod(0700, $path) or die "chmod: $path: $!\n";
    }

    # tell the user
    foreach my $row (@{$projects{$project}{ROWS}}) {
        print "mapping ${$row}{ONION_ADDRESS} to ${$row}{DNS_DOMAIN} project $project\n";
    }
}


##################################################################

# in-template settings; don't confuse the two modules
# this: https://nginx.org/en/docs/http/ngx_http_proxy_module.html (used)
# versus: https://nginx.org/en/docs/stream/ngx_stream_proxy_module.html (not used)

# default-set values
&SetEnv("block_err", "This action is not supported over Onion yet, sorry.");
&SetEnv("force_https", 1);
&SetEnv("hard_mode", 0);
&SetEnv("nginx_action_abort", "return 500");
&SetEnv("nginx_block_busy_size", "16k");
&SetEnv("nginx_block_count", 8);
&SetEnv("nginx_block_size", "8k");
&SetEnv("nginx_cache_min_uses", 1);
&SetEnv("nginx_cache_seconds", 60); # 0 = off
&SetEnv("nginx_cache_size", "256m");
&SetEnv("nginx_hash_bucket_size", 128);
&SetEnv("nginx_hello_onion", 1);
&SetEnv("nginx_resolver", "8.8.8.8");
&SetEnv("nginx_rlim", 256);
&SetEnv("nginx_syslog", "error"); # https://nginx.org/en/docs/ngx_core_module.html#error_log
&SetEnv("nginx_template", "$here/templates.d/nginx.conf.txt");
&SetEnv("nginx_timeout", 15);
&SetEnv("nginx_tmpfile_size", "256m");
&SetEnv("nginx_workers", "auto");
&SetEnv("paths_contain_onions", 0);
&SetEnv("preserve_cookie", "~-=~=-~");
&SetEnv("preserve_preamble", "[>@\\\\s]");
&SetEnv("project", "default");
&SetEnv("projects_home", "$here/projects.d");
&SetEnv("softmap_nginx_workers", "auto"); # nginx_workers * softmap_tor_workers
&SetEnv("softmap_tor_workers", 2); # MUST BE NUMERIC > 1
&SetEnv("ssl_tool", "$here/lib.d/make-selfsigned-wildcard-ssl-cert.sh");
&SetEnv("suppress_header_csp", 0); # 0 = try rewriting; 1 = elide completely
&SetEnv("suppress_header_hpkp", 1); # 1 = elide completely
&SetEnv("suppress_header_hsts", 1); # 1 = elide completely
&SetEnv("suppress_methods_except_get", 0); # 1 = GET/HEAD Only
&SetEnv("suppress_tor2web", 1); # 1 = block access by tor2web sites
&SetEnv("template_tool", "$here/lib.d/expand-template.pl");
&SetEnv("tor_intros_per_daemon", 3);
&SetEnv("tor_single_onion", 1);
&SetEnv("tor_syslog", "notice"); # https://www.torproject.org/docs/tor-manual.html.en
&SetEnv("tor_template", "$here/templates.d/tor.conf.txt");
&SetEnv("tor_worker_prefix", "hs");
&SetEnv("x_from_onion_value", "1");

# default-empty variables
my @set_blank = qw(
    block_host
    block_host_re
    block_location
    block_location_re
    block_origin
    block_origin_re
    block_param
    block_param_re
    block_path
    block_path_re
    block_referer
    block_referer_re
    cookie_lock
    debug_trap
    extra_processing_csv
    foreignmap_csv
    hardcoded_endpoint_csv
    host_blacklist
    host_blacklist_re
    host_whitelist
    host_whitelist_re
    no_cache_content_type
    no_cache_host
    origin_blacklist
    origin_blacklist_re
    origin_whitelist
    origin_whitelist_re
    param_blacklist
    param_blacklist_re
    param_whitelist
    param_whitelist_re
    path_blacklist
    path_blacklist_re
    path_whitelist
    path_whitelist_re
    preserve_csv
    redirect_host_csv
    redirect_location_csv
    redirect_path_csv
    referer_blacklist
    referer_blacklist_re
    referer_whitelist
    referer_whitelist_re
    user_agent_blacklist
    user_agent_blacklist_re
    user_agent_whitelist
    user_agent_whitelist_re
    );

foreach my $var (@set_blank) {
    &SetEnv($var, "");
}

&SetEnv("SCRIPT_NAMES", "bounce.sh debugoff.sh debugon.sh harvest.sh maps.sh nxreload.sh start.sh status.sh stop.sh syntax.sh torreload.sh");
&SetEnv("SCRIPT_PAUSE", 5);

# dynamic settings: overridable / may be given a global setting

&SetEnv("CERT_PREFIX", $unset_variable);
&SetEnv("LOG_DIR", $unset_variable);
&SetEnv("SSL_DIR", $unset_variable);

# nb: see DoMap() for non-overridable, project-local settings

# fetch the config

if ($#ARGV < 0) {
    $config = "onions.conf"; # in $here
}
else {
    $config = $ARGV[0];
}

die "$config: no such file / missing configuration: $config\n" unless (-f $config);

open(CONFIG, $config) or die "$config: $!\n";
@config = <CONFIG>;
close(CONFIG);
@config = &JoinLines(@config);
@config = grep(!/^\s*(#.*)?$/, @config);
chomp(@config);

# run it

foreach (@config) {
    my ($cmd, @args) = split;

    if ($cmd eq "set") {
        my $var = shift(@args);
        my $val = "@args";
        &SetEnv($var, $val, 'config-file');
    }
    elsif ($cmd eq "hardmap") {
        &DoMap($cmd, @args);
    }
    elsif ($cmd eq "softmap") {
        &DoMap($cmd, @args);
    }
    elsif ($cmd eq "foreignmap") {
        &DoForeign($cmd, @args);
    }
    else {
        die "error: what does '$cmd @args' mean?";
    }
}

# what did we get?
warn "dumping final state\n";
warn Dumper(\%projects);

# create a home
&MakeDir($ENV{PROJECTS_HOME});

# prep the foreigns
my @flist = ();
foreach $domain (sort keys %foreign_by_domain) {
    my $x;
    my $onion = $foreign_by_domain{$domain};
    my @elements = ();

    $x = $onion; # onion
    push(@elements, $x);
    $x = &SlashDot($x); # _RE
    push(@elements, $x);
    $x = &SlashDot($x); # _RE2
    push(@elements, $x);

    $x = $domain; # domain
    push(@elements, $x);
    $x = &SlashDot($x); # _RE
    push(@elements, $x);
    $x = &SlashDot($x); # _RE2
    push(@elements, $x);

    push(@flist, join(",", @elements));
}
&SetEnv("foreignmap_csv", join(" ", @flist));

# lay it out
foreach my $project (sort keys %projects) {
    &DoProject($project);
}

# done
exit 0;

##################################################################
