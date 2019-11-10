#!/usr/bin/perl -n
next unless /##/o;
s/\s+/ /go;
s/^\s//;
s/\s$//;

($opts, $docs) = split(/\s*##\s*/);
$opts =~ s/x--/--/g;
$opts =~ s/\*//g;
$opts =~ s/\)$//;

if ($opts =~ /\|/) {
    $opts = "<$opts>";
}

if ($docs =~ /\|/) {
    ($args, $docs) = split(/\s*\|\s*/, $docs);
    $args = " $args";
} else {
    $args = '';
}

print "  $ARGV $opts$args\n    $docs\n";
