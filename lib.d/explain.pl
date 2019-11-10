#!/usr/bin/perl -n
next unless /##/o;

s/\s+/ /go;
s/^\s//;
s/\s$//;

($opts, $docs) = split(/\s*##\s*/);
$opts =~ s/x--/--/g;
$opts =~ s/\)$//;

$key = $opts;

if ($opts =~ /\|/) {
    $opts = "<$opts>";
}

if ($docs =~ /\|/) {
    ($args, $docs) = split(/\s*\|\s*/, $docs);
    $args = " $args";
} else {
    $args = '';
}

$foo{$key} = "  $ARGV $opts$args\n    $docs\n\n";

END {
    foreach $key (sort keys %foo) {
        print $foo{$key};
    }
}
