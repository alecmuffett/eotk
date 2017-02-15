#!/usr/bin/perl

# data structures

my %data = (); # $data{$project}{$master_onion}{$worker_onion} = 1;
my %dnsmap = (); # $dnsmap{$master_onion} = $dns_domain

# input

while (<>) {
    my ($project,
	$softmap,
	$master_onion,
	$dns_domain,
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

$indent = "    ";

print <<"EOT";
INITIAL_DELAY: 60
# PUBLISH_CHECK_INTERVAL
# REFRESH_INTERVAL: 600
EOT

print "services:\n";
foreach my $project (sort keys %data) {
    print "# PROJECT $project\n";
    foreach my $master_onion (sort {$dnsmap{$a} cmp $dnsmap{$b}} keys %{$data{$project}}) {
        my $keyfile = "secrets.d/$master_onion.key";
        $keyfile =~ s!\.onion\.!.!;

        print "$indent# $dnsmap{$master_onion} => $master_onion\n";
        print "$indent- key: $keyfile\n";
        print "$indent  instances:\n";

	foreach my $worker_onion (sort keys %{$data{$project}{$master_onion}}) {
            print "$indent$indent- address: $worker_onion\n";
        }
    }
}

# done

exit 0;
