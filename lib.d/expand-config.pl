#!/usr/bin/perl -w
# eotk (c) 2017 Alec Muffett

if (-t STDIN) { # stderr is already redirected...
    if (open(DOTS, ">/dev/tty")) {
        $dots = 1;
    }
}

sub HardOnion { # DEPRECATED
    chomp($onion = `eotk gen`);
    return "secrets.d/$onion"; # DEPRECATED
}

sub SoftOnion {
    chomp($onion = `eotk gen`);
    $onion =~ s/\.key//;
    return $onion; # THIS IS THE UNIFIED FORMAT
}

sub Lookup {
    my $var = shift;
    if ($var =~ /^NEW_(HARD_)?ONION$/) { # NEW_HARD_ONION DEPRECATED
        return &SoftOnion();
    }
    if ($var =~ /^NEW_SOFT_ONION$/) { # DEPRECATED
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
