#!/usr/bin/perl -w
# eotk (c) 2017 Alec Muffett

use Data::Dumper;

die "$0: needs EOTK_HOME environment variable to be set\n"
    unless (defined($ENV{EOTK_HOME}));

# state

my %projects = ();
my $unset_variable = "<-UNSET-VARIABLE->";
my $here = $ENV{EOTK_HOME};

chdir($here) or die "chdir: $here: $!\n";

##################################################################

sub SetEnv {
    my ($var, $val, $why) = @_;
    die "bad varname: $var\n" if ($var !~ /^[A-Za-z_]\w+/);
    $var =~ tr/a-z/A-Z/;
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

sub Dotify { # dotify a regexp
    warn "Dotify @_\n";
    my $arg = shift;
    $arg =~ s!\.!\\.!g;
    return $arg;
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
    my $foo;

    my $project = $ENV{PROJECT}; # the instantaneous value of `project` is stored

    if (!defined($projects{$project})) {
        $projects{$project} = {};
    }

    if (!defined($projects{$project}{TYPE})) {
        $projects{$project}{TYPE} = $what;
        $projects{$project}{IS_SOFTMAP} = ($what eq "softmap" ? 1 : 0);
    }

    $foo = $projects{$project}{TYPE};
    if ($foo ne $what) {
        die "DoMap: you cannot add $what ($from/$to) to an existing $foo project\n";
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

    warn "mapping $what($keyfile) from=$onion to=$to san=(@subdomains)\n";

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
    $row{DNS_DOMAIN} = $to;
    $row{DNS_DOMAIN_RE} = &Dotify($to);
    $row{ONION_ADDRESS} = $onion;
    $row{ONION_ADDRESS_RE} = &Dotify($onion);
    $row{KEYFILE} = $keyfile;

    warn Dumper(\%row);

    # push a reference to the row
    push(@{$projects{$project}{ROWS}}, \%row);
}

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

    # script settings - we'll meed this further down
    my @scriptrows = (); # empty except for softmap

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

            # poke the script settings
            push(@scriptrows, {'TOR_DIR' => $hs_dir});
        }
    }
    else {
        # setup tor hs directories and keys
        foreach my $row (@{$projects{$project}{ROWS}}) {
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
        my $path = "$ENV{PROJECT_DIR}/$script.sh";
        my $cmd = "$ENV{TEMPLATE_TOOL} templates.d/$script.txt >$path";
        &Pipeify($cmd, @scriptrows);
        chmod(0700, $path) or die "chmod: $path: $!\n";
    }

    # tell the user
    foreach my $row (@{$projects{$project}{ROWS}}) {
        print "project $project maps ${$row}{ONION_ADDRESS} to ${$row}{DNS_DOMAIN}\n";
    }
}


##################################################################

# where stuff lives

&SetEnv("projects_home", "$here/projects.d");
&SetEnv("project", "default");

&SetEnv("nginx_template", "$here/templates.d/nginx.txt");
&SetEnv("tor_template", "$here/templates.d/tor.txt");

&SetEnv("ssl_tool", "$here/tools/make-selfsigned-wildcard-ssl-cert.sh");
&SetEnv("template_tool", "$here/tools/expand-template.pl");

# in-template settings

&SetEnv("nginx_hello_onion", 1);
&SetEnv("nginx_resolver", "127.0.0.1");
&SetEnv("nginx_rlim", 1024);
&SetEnv("nginx_timeout", 30);
&SetEnv("nginx_workers", 5);

&SetEnv("tor_intros_per_daemon", 3);
&SetEnv("tor_single_onion", 0);
&SetEnv("tor_worker_prefix", "hs");

&SetEnv("softmap_tor_workers", 4);
&SetEnv("softmap_nginx_workers", 5 * 4);

&SetEnv("SCRIPT_NAMES", "start stop bounce debugon debugoff syntax");
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
chomp(@config = grep(!/^\s*(#.*)?$/, <CONFIG>));
close(CONFIG);

# run it

foreach (@config) {
    my ($cmd, @args) = split;

    if ($cmd eq "set") {
        my $var = shift(@args);
        my $val = "@args";
        &SetEnv($var, $val);
    }
    elsif ($cmd eq "hardmap") {
        &DoMap($cmd, @args);
    }
    elsif ($cmd eq "softmap") {
        &DoMap($cmd, @args);
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

# lay it out
foreach my $project (sort keys %projects) {
    &DoProject($project);
}

# done
exit 0;

##################################################################
