#!/bin/sh
exec perl -x $0 "$@";
#!perl
# eotk (c) 2017-2020 Alec Muffett

# data structures

my %data = (); # $data{$project}{$master_onion}{$worker_onion} = 1;
my %dnsmap = (); # $dnsmap{$master_onion} = $dns_domain

# input

while (<>) {
    my ($master_onion,
	$dns_domain,
        $project,
	$softmap,
	$via,
	$worker_onion) = split(" ");

    die "bad format: not softmap config: $_" if $softmap ne "softmap";
    die "bad format: not via tag: $_" if $via ne "via";

    $data{$project}{$master_onion}{$worker_onion} = 1;

    if (defined($dnsmap{$master_onion})) { # check consistency
        die "dns master onion mismatch: $dnsmap{$master_onion} vs: $_"
            if ($dns_domain ne $dnsmap{$master_onion});
    }
    else { # set
        $dnsmap{$master_onion} = $dns_domain;
    }
}

# output

$indent = "  ";

print "services:\n";
foreach my $project (sort keys %data) {
    print "# PROJECT $project\n";
    foreach my $master_onion (sort {$dnsmap{$a} cmp $dnsmap{$b}} keys %{$data{$project}}) {
        my $keyfile = "$ENV{EOTK_HOME}/secrets.d/$master_onion.key";
        $keyfile =~ s!\.onion\.!.!; # remove .onion from MIDDLE OF FILENAME

        print "${indent}# $dnsmap{$master_onion} => $master_onion\n";
        print "${indent}- key: $keyfile\n";
        print "${indent}${indent}instances:\n";

	foreach my $worker_onion (sort keys %{$data{$project}{$master_onion}}) {
            $worker = $worker_onion;
            $worker =~ s!\.onion!!; # OB vomits on trailing ".onion"
            print "${indent}${indent}${indent}- address: '$worker'\n";
        }
    }
}

# done

exit 0;
