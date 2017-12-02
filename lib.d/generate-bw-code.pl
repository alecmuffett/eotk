#!/usr/bin/perl

$warning = "(generated)";
$begin = "# ---- BEGIN GENERATED CODE ---- -*- awk -*-\n\n";
$end = "# ---- END GENERATED CODE ----\n";

$indent = "  ";
@polite = ();
@black = ();
@white = ();
@tail = ();

while (<DATA>) {
    next if /^#/;
    next if /^\s*$/;

    chomp;
    s/\s+/ /g;
    ($how, $lc_what, $condition) = split(/\s+/, $_, 3);
    $uc_what = uc($lc_what);

    if ($how eq "bwlist") {
        $uc_bl = "${uc_what}_BLACKLIST_RE";
        $uc_wl = "${uc_what}_WHITELIST_RE";
        $lc_bl = lc($uc_bl);
        $lc_wl = lc($uc_wl);
        $flag = "\$non_whitelist_${lc_what}";

        push(@black, "%%IF %$uc_bl%\n");
        push(@black, "# check $lc_bl $warning\n");
        push(@black, "%%CSV %$uc_bl%\n");
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
    elsif ($how eq "block") {
        push(@polite, "%%IF %$uc_what%\n");
        push(@polite, "# polite block for $lc_what $warning\n");
        push(@polite, "%%CSV %$uc_what%\n");
        push(@polite, "$condition { return 403 \"%BLOCK_ERR%\"; }\n");
        push(@polite, "%%ENDCSV\n");

        push(@polite, "%%ELSE\n");
        push(@polite, "# no polite block for $lc_what $warning\n");
        push(@polite, "%%ENDIF\n");
        push(@polite, "\n");
    }
    else {
        die "bad config line at line $.: $_\n";
    }
}

open(OUT, ">nginx-generated-blocks.conf") || die;
print OUT $indent x 2, $begin;
print OUT $indent x 2, "# polite blocks $warning\n\n";
foreach $x (@polite) {
    print OUT $indent x 2, $x;
}
print OUT "\n";

print OUT $indent x 2, "# blacklists $warning\n\n";
foreach $x (@black) {
    print OUT $indent x 2, $x;
}
print OUT "\n";

print OUT $indent x 2, "# whitelists $warning\n\n";
foreach $x (@white) {
    print OUT $indent x 2, $x;
}
print OUT "\n";
print OUT $indent x 2, $end;
close(OUT);

open(OUT, ">nginx-generated-checks.conf") || die;
print OUT $indent x 3, $begin;
print OUT $indent x 3, "# whitelist checks $warning\n\n";
foreach $x (@tail) {
    print OUT $indent x 3, $x;
}
print OUT "\n";
print OUT $indent x 3, $end;
close(OUT);

# NB: AVOID `location` DIRECTIVE IN THE CONDITIONALS, BECAUSE IT
# TRIGGERS A HANDLER...
__END__;

# blocks: issue a 403
block suppress_tor2web if ( $http_x_tor2web )
block block_host if ( $host = "%0%" )
block block_host_re if ( $host ~* "%0%" )
block block_path if ( $uri = "%0%" )
block block_path_re if ( $uri ~* "%0%" )
# legacy
block block_location location %0%
block block_location_re location ~* "%0%"

# blacklists and whitelists: issue a 500
# nb: second argument gets interpolated into variablenames
bwlist user_agent if ( $http_user_agent ~* "%0%" )
bwlist referer if ( $http_referer ~* "%0%" )
bwlist host if ( $http_host ~* "%0%" )
bwlist path if ( $uri ~* "%0%" )
