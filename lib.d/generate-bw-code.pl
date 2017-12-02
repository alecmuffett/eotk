#!/usr/bin/perl

$warning = "(generated code)";

@black = ();
@white = ();
@tail = ();

while (<DATA>) {
    next if /^#/;
    next if /^\s*$/;

    chomp;
    s/\s+/ /g;
    ($how, $lc_what, $condition) = split(/\s+/, $_, 3);

    if ($how eq "bwlist") {
        $uc_what = uc($lc_what);
        $uc_bl = "${uc_what}_BLACKLIST_RE";
        $uc_wl = "${uc_what}_WHITELIST_RE";
        $lc_bl = lc($uc_bl);
        $lc_wl = lc($uc_wl);
        $flag = "\$non_whitelist_${lc_what}";

        push(@black, "%%IF %$uc_bl%\n");
        push(@black, "# check $lc_bl $warning\n");
        push(@black, "%%CSV $uc_bl\n");
        push(@black, "$condition { %NGINX_ACTION_ABORT%; }\n");
        push(@black, "%%ENDCSV\n");
        push(@black, "%%ELSE\n");
        push(@black, "# no $lc_bl $warning\n");
        push(@black, "%%ENDIF\n");
        push(@black, "\n");

        push(@white, "%%IF %$uc_wl%\n");
        push(@white, "# check $lc_wl $warning\n");
        push(@white, "set $flag 1;\n");
        push(@white, "%%CSV %$uc_wl%\n");
        push(@white, "$condition { set $flag 0; }\n");
        push(@white, "%%ENDCSV\n");
        push(@white, "%%ELSE\n");
        push(@white, "# no $lc_wl $warning\n");
        push(@white, "%%ENDIF\n");
        push(@white, "\n");

        push(@tail, "%%IF %$uc_wl%\n");
        push(@tail, "# check success of $lc_wl $warning\n");
        push(@tail, "if ( $flag ) { %NGINX_ACTION_ABORT%; }\n");
        push(@tail, "%%ELSE\n");
        push(@tail, "# no check for success of $lc_wl $warning\n");
        push(@tail, "%%ENDIF\n");
        push(@tail, "\n");
    }
    else {
        die "bad config line at line $.: $_\n";
    }
}


print "    # blacklists\n\n";
foreach $x (@black) {
    print "    ", $x;
}

print "    # whitelists\n\n";
foreach $x (@white) {
    print "    ", $x;
}

print "----------------\n\n";

print "      # whitelist checks\n";
foreach $x (@tail) {
    print "      ", $x;
}


# NB: AVOID `location` DIRECTIVE IN THE CONDITIONALS, BECAUSE IT
# TRIGGERS A HANDLER...
__END__;

# blacklists and whitelists
bwlist user_agent if ( $http_user_agent ~* "%0%" )
bwlist referer if ( $http_referer ~* "%0%" )
bwlist host if ( $http_host ~* "%0%" )
bwlist path if ( $uri ~* "%0%" )
