#!/usr/bin/perl -w
# eotk (c) 2017 Alec Muffett

if (-t STDIN) { # stderr is already redirected...
    if (open(DOTS, ">/dev/tty")) {
        $dots = 1;
    }
}

sub GenOnion {
    my $version = shift;
    chomp($onion = `env ONION_VERSION=$version eotk gen`);
    return $onion; # THIS IS NOW THE UNIFIED FORMAT
}

sub Lookup {
    my $var = shift;

    foreach $deprecated (qw(NEW_HARD_ONION NEW_SOFT_ONION)) {
        die "Lookup: $deprecated is no longer supported syntax\n"
            if $var =~ /$deprecated/;
    }

    if ($var =~ /^NEW_(V3_)?ONION$/) {
        my $version = $1 ? 3 : 2;
        return &GenOnion($version);
    }

    if (defined($ENV{$var})) {
        return $ENV{$var};
    }
    die "Lookup: variable named '$var' not set\n";
}

while (<>) {
    if ($dots) {
        print DOTS ".";
    }
    s/%([\w+]+)%/&Lookup($1)/ge;
    print;
}

if ($dots) {
    print DOTS "\n";
    close(DOTS);
}

exit 0;
