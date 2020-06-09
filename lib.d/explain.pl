#!/bin/sh
exec perl -nx $0 "$@";
#!perl
# eotk (c) 2017-2020 Alec Muffett

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
    $target_width = 60;
    foreach $opts (sort keys %foo) {
        ($args, $docs) = @{$foo{$opts}};
        $opts = "<$opts>" if ($opts =~ /\|/);
        print "  $ARGV $opts$args\n";
        @stack = ([]);
        @words = split(" ", $docs);

        while ($word = shift(@words)) {
            $render = "@{$stack[$#stack]}";
            if (length $render >= $target_width) {
                push(@stack, []);
            }
            push(@{$stack[$#stack]}, $word);
        }
        foreach $line (@stack) {
            print "    @{$line}\n";
        }
        print "\n";
    }
}
