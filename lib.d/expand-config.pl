#!/usr/bin/perl -w
# eotk (c) 2017 Alec Muffett

if (-t STDIN) { # stderr is already redirected...
    if (open(DOTS, ">/dev/tty")) {
        $dots = 1;
    }
}

sub HardOnion {
    chomp($onion = `eotk gen`);
    return "secrets.d/$onion";
}

sub SoftOnion {
    chomp($onion = `eotk gen`);
    $onion =~ s/\.key//;
    return $onion;
}

sub Lookup {
    my $var = shift;
    if ($var =~ /^NEW_(HARD_)?ONION$/) {
        return &HardOnion();
    }
    if ($var =~ /^NEW_SOFT_ONION$/) {
        return &SoftOnion();
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
