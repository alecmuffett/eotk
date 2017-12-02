#!/usr/bin/perl

$warning = "(generated)";
$begin = "# ---- BEGIN GENERATED CODE ---- -*- awk -*-\n\n";
$end = "# ---- END GENERATED CODE ----\n";

$indent = "  ";
@polite = ();
@redirect = ();
@black = ();
@white = ();
@tail = ();


sub blackwhite {
    my ($operator, $lc_what, $a, $b) = @_;
    my $uc_what = uc($lc_what);
    my $condition = "if ( $a $operator $b )";

    if ($operator eq "~*") {
        $uc_bl = "${uc_what}_BLACKLIST_RE";
        $uc_wl = "${uc_what}_WHITELIST_RE";
    }
    elsif ($operator eq "=") {
        $uc_bl = "${uc_what}_BLACKLIST";
        $uc_wl = "${uc_what}_WHITELIST";
    }
    else {
        die "bad blackwhite operator";
    }

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


while (<DATA>) {
    next if /^#/;
    next if /^\s*$/;

    chomp;
    s/\s+/ /g;
    ($how, $lc_what, $condition) = split(/\s+/, $_, 3);

    if ($how eq "bwlist") {
        #&blackwhite("=", $lc_what, split(" ", $condition));
        &blackwhite("~*", $lc_what, split(" ", $condition));
    }
    elsif ($how eq "block") {
        my $uc_what = uc($lc_what);
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
    elsif ($how eq "redirect") {
        my $uc_what = uc($lc_what);
        push(@redirect, "%%IF %$uc_what%\n");
        push(@redirect, "# redirect $lc_what: 1=regexp,2=dest,3=code $warning\n");
        push(@redirect, "%%CSV %$uc_what%\n");
        push(@redirect, "$condition { return %3% %2%\$request_uri; }\n");
        push(@redirect, "%%ENDCSV\n");
        push(@redirect, "%%ELSE\n");
        push(@redirect, "# no redirect $lc_what $warning\n");
        push(@redirect, "%%ENDIF\n");
        push(@redirect, "\n");
    }
    else {
        die "bad config line at line $.: $_\n";
    }
}

open(OUT, ">nginx-generated-blocks.conf") || die;
print OUT $indent x 2, $begin;
print OUT $indent x 2, "# polite blocks $warning\n\n";
foreach $x (@polite) {
    print OUT $indent x 2 if ($x !~ /^\s*$/);
    print OUT $x;
}
print OUT "\n";

print OUT $indent x 2, "# blacklists $warning\n\n";
foreach $x (@black) {
    print OUT $indent x 2 if ($x !~ /^\s*$/);
    print OUT $x;
}
print OUT "\n";

print OUT $indent x 2, "# redirects $warning\n\n";
foreach $x (@redirect) {
    print OUT $indent x 2 if ($x !~ /^\s*$/);
    print OUT $x;
}
print OUT "\n";

print OUT $indent x 2, "# whitelists $warning\n\n";
foreach $x (@white) {
    print OUT $indent x 2 if ($x !~ /^\s*$/);
    print OUT $x;
}
print OUT "\n";
print OUT $indent x 2, $end;
close(OUT);

open(OUT, ">nginx-generated-checks.conf") || die;
print OUT $indent x 3, $begin;
print OUT $indent x 3, "# whitelist checks $warning\n\n";
foreach $x (@tail) {
    print OUT $indent x 3 if ($x !~ /^\s*$/);
    print OUT $x;
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
# query parameters
block block_param if ( $arg_%1% = "%2%" )
block block_param_re if ( $arg_%1% ~* "%2%" )

# redirects
redirect redirect_host_csv if ( $host ~* "%1%" )
redirect redirect_path_csv if ( $uri ~* "%1%" )
# legacy
redirect redirect_location_csv location ~* "%1%"

# blacklists and whitelists: issue a 500
# nb: second argument gets interpolated into variablenames
bwlist user_agent $http_user_agent "%0%"
bwlist referer $http_referer "%0%"
bwlist host $http_host "%0%"
bwlist path $uri "%0%"
bwlist param $arg_%1% "%2%"
