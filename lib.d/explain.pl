#!/usr/bin/perl -n
next unless /##/o;

s/\s+/ /go;
s/^\s//;
s/\s$//;

($opts, $docs) = split(/\s*##\s*/);
$opts =~ s/x--/--/g;
$opts =~ s/\|\*//;
$opts =~ s/\)$//;

if ($docs =~ /\|/) {
    ($args, $docs) = split(/\s*\|\s*/, $docs);
    $args = " $args";
} else {
    $args = '';
}

$foo{$opts} = [$args, $docs];

END {
    foreach $opts (sort keys %foo) {
        ($args, $docs) = @{$foo{$opts}};
        $opts = "<$opts>" if ($opts =~ /\|/);
        print "  $ARGV $opts$args\n";
        print "    $docs\n\n";
    }
}
