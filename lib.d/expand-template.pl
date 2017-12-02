#!/usr/bin/perl -w
# eotk (c) 2017 Alec Muffett

use Data::Dumper;

my $debug = 1;
my %used = (); # debug tracking for used variable names
my @scopes = (); # lookaside contexts for local variables
my @dataset = (); # the input rules
my @template = (); # the template, obvs

# ------------------------------------------------------------------

sub Warn {
    my $warning = join('', @_);
    warn $warning if ($debug);
}

sub Lookup {
    my $var = shift;

    return '%' if ($var eq '');

    $used{$var} = 1;

    foreach $symref (@scopes) {
        if (defined(${$symref}{$var})) {
            return ${$symref}{$var};
        }
    }

    if (defined($ENV{$var})) {
        return $ENV{$var};
    }

    &Warn("start dumping scopes\n");
    foreach $symref (@scopes) {
        &Warn(Dumper($symref));
    }
    &Warn("finish dumping scopes\n");

    die "lookup: variable named '$var' not set\n";
}

sub Evaluate {
    &Warn("Evaluate @_");
    my @args = @_;

    if ($#args < 0) {
        &Warn("EvaluateUndef");
        return 0;
    }

    if ($#args == 0) {     # single word? return it, let Perl evaluate
        &Warn("Evaluate0 $args[0]");
        return $args[0];
    }

    if ($#args == 1 and (
            ($args[0] eq "not") or
            ($args[0] eq "!"))) {
        &Warn("Evaluate1-not $args[1]");
        return not $args[1];
    }

    if ($#args == 2) {
        my ($a, $op, $b, @junk) = @args;
        &Warn("Evaluate2 $a");
        &Warn("Evaluate2 $op");
        &Warn("Evaluate2 $b");

        # numeric
        return ($a == $b) if ($op eq "==");
        return ($a != $b) if ($op eq "!=");
        return ($a >= $b) if ($op eq ">=");
        return ($a <= $b) if ($op eq "<=");
        return ($a > $b) if ($op eq ">");
        return ($a < $b) if ($op eq "<");

        # string
        return ($a eq $b) if ($op eq "eq");
        return ($a ne $b) if ($op eq "ne");
        return ($a ge $b) if ($op eq "ge");
        return ($a le $b) if ($op eq "le");
        return ($a gt $b) if ($op eq "gt");
        return ($a lt $b) if ($op eq "lt");

        # logic
        return ($a and $b) if ($op eq "and");
        return ($a or $b) if ($op eq "or");
        return ($a xor $b) if ($op eq "xor");

        # substr
        return (index($a, $b) >= 0) if ($op eq "contains");
        return !(index($a, $b) >= 0) if ($op eq "!contains");
    }

    warn "evaluate: expression not parsed, returning for verbatim eval as string: @args\n";
    return "@args";
}

sub Echo {
    &Warn("Echo1 @_");
    my $line = shift;
    if ($line =~ /%/) {
        $line =~ s/%([\w+]*)%/&Lookup($1)/ge;
    }
    &Warn("Echo2 $line");
    print $line;
}

sub FindMatching {
    my $btoken = shift;
    my $etoken = shift;
    my $i = shift;
    my $nestlevel = 0;
    &Warn("looking for $etoken starting from $i $template[$i]");
    for (undef; $i <= $#template; $i++) {
        if ($template[$i] =~ /^\s*$btoken\b/) {
            $nestlevel++;
            next;
        }
        if ($template[$i] =~ /^\s*$etoken\b/) {
            if ($nestlevel > 0) {
                &Warn("found nested($nestlevel) $etoken at $i $template[$i]");
                $nestlevel--;
                next;
            }
            &Warn("found $etoken at $i $template[$i]");
            return $i;
        }
    }
    die "runaway search for $etoken\n";
}

sub PrintExpansion {
    my ($begin, $end) = @_;     # inclusive

    &Warn("expand begin: $begin $template[$begin]");
    &Warn("expand end: $end $template[$end]");

    my @vars = split(" ", $dataset[0]); # 1st line is vars
    &Warn("vars: @vars\n");

    # push down a scope
    my %scope = ();
    unshift(@scopes, \%scope);
    &Warn("scope $#scopes pushed\n");

    # load the variables into the local scope
    for (my $i = 1; $i <= $#dataset; $i++) { # 2nd line onwards

        # split the input
        my @vals = split(" ", $dataset[$i]);
        &Warn("vals: @vals\n");

        # sanity check
        die "array mismatch:\n@vars\n@vals\n" if ($#vars != $#vals);

        # populate the scope
        my $j = 0;
        foreach my $val (@vals) {
            $var = $vars[$j++];
            $scope{$var} = $val;
            &Warn("setting $var = $val in scope $#scopes\n");
        }

        # print the block
        &PrintBlock($begin, $end);
    }

    # nuke the scope
    shift(@scopes);
    &Warn("scope popped, now at $#scopes\n");
}

sub PrintRange {
    my ($line, $begin, $end) = @_;

    &Warn("range begin: $begin $template[$begin]");
    &Warn("range end: $end $template[$end]");

    # limits
    $line =~ s/%([\w+]*)%/&Lookup($1)/ge;
    my ($crap, $var, $start, $finish, @rest) = split(" ", $line);
    &Warn("range: $var, $start, $finish\n");

    # push down a scope
    my %scope = ();
    unshift(@scopes, \%scope);
    &Warn("scope $#scopes pushed\n");

    # loop
    for (my $val = $start; $val <= $finish; $val++) {
        # populate the scope
        $scope{$var} = $val;

        # print the block
        &PrintBlock($begin, $end);
    }

    # nuke the scope
    shift(@scopes);
    &Warn("scope popped, now at $#scopes\n");
}

sub PrintCsv {
    my ($line, $begin, $end) = @_;

    &Warn("csv begin: $begin $template[$begin]");
    &Warn("csv end: $end $template[$end]");

    # limits
    $line =~ s/%([\w+]*)%/&Lookup($1)/ge;
    my ($crap, @csvs) = split(" ", $line);
    &Warn("csv: @csvs\n");

    foreach my $csv (@csvs) {
        # push down a scope
        my %scope = ();
        unshift(@scopes, \%scope);
        &Warn("scope $#scopes pushed\n");

        # %0% = whole thing
        $scope{"0"} = $csv;

        # %1%... = elements
        my $i = 1;
        foreach my $element (split(/,/, $csv)) {
            $scope{"$i"} = $element;
            $i++;
        }

        # print the block
        &PrintBlock($begin, $end);

        # nuke the scope
        shift(@scopes);
        &Warn("scope popped, now at $#scopes\n");
    }
}

sub PrintIf {         # having %%ELSE makes this a little more complex
    my $start = shift;
    my $cond = $template[$start];
    my $nestlevel = 0;

    &Warn("found %%IF at $start: $cond");

    my $fi_ptr = undef;
    my $else_ptr = undef;

    for (my $i = $start + 1; $i <= $#template; $i++) {
        if ($template[$i] =~ /^\s*%%IF\b/) { # nested
            &Warn("found nested($nestlevel) %%IF at $i: $template[$i]");
            $nestlevel++;
            next;
        }

        if ($template[$i] =~ /^\s*%%ENDIF\b/) {
            if ($nestlevel > 0) {
                &Warn("found nested($nestlevel) %%ENDIF at $i: $template[$i]");
                $nestlevel--;
                next;
            }
            &Warn("found %%ENDIF at $i: $template[$i]");
            $fi_ptr = $i;
            last;
        }

        if ($template[$i] =~ /^\s*%%ELSE\b/) {
            next if ($nestlevel > 0); # stay blind to nested code
            &Warn("found %%ELSE at $i: $template[$i]");
            $else_ptr = $i;
        }
    }
    die "runaway search for %%ENDIF\n" if (!defined($fi_ptr));

    # expand all %VARIABLES%
    $cond =~ s/%([\w+]*)%/&Lookup($1)/ge;
    &Warn("if-expand: $cond");

    # evaluate the resulting string
    my ($ifstmt, @args) = split(" ", $cond);
    my $result = &Evaluate(@args);
    &Warn("result: $result\n");

    # act on the result
    if ($result) {              # true
        &Warn("print true block\n");
        my $begin2 = $start + 1;
        my $end2 = defined($else_ptr) ? ($else_ptr - 1) : ($fi_ptr - 1);
        &PrintBlock($begin2, $end2);
    }
    elsif (defined($else_ptr)) { # false, maybe print else-block?
        &Warn("print else block\n");
        my $begin2 = $else_ptr + 1;
        my $end2 = $fi_ptr - 1;
        &PrintBlock($begin2, $end2);
    }

    return $fi_ptr;
}

sub FindMatchingEnd {
    return &FindMatching('%%BEGIN', '%%END', @_);
}

sub FindMatchingEndRange {
    return &FindMatching('%%RANGE', '%%ENDRANGE', @_);
}

sub FindMatchingEndCsv {
    return &FindMatching('%%CSV', '%%ENDCSV', @_);
}

sub Cat { # THIS IS NOT THE SAME AS "#include" / CONTENTS NOT PROCESSED
    &Warn("Cat: @_\n");
    my $flist = shift;
    my ($junk, @filenames) = split(" ", $flist);
    foreach my $file (@filenames) {
        &Warn("Catting: $file\n");
        open(FILE, $file) || die "Cat: $file: $!\n";
        my $line;
        while ($line = <FILE>) {
            print $line;        # why bother slurping?
        }
        close(FILE);
    }
}

sub Slurp {
    &Warn("Slurp: @_\n");
    my $flist = shift;
    my ($junk, @filenames) = split(" ", $flist);
    my @lines = ();
    foreach my $file (@filenames) {
        &Warn("Slurping: $file\n");
        open(FILE, $file) || die "Slurp: $file: $!\n";
        push(@lines, <FILE>);
        close(FILE);
    }
    return @lines;
}

sub PrintBlock {
    my ($begin, $end) = @_;     # inclusive

    &Warn("PrintBlock: begin at $begin, end at $end\n");

    if ($begin > $end) {
        warn "begin: $template[$begin]";
        warn "end: $template[$end]";
        if (($begin - $end) == 1) {
            warn "PrintBlock: info: empty block\n";
        } else {
            die "PrintBlock: end($end) before begin($begin)\n";
        }
        return;
    }

    for (my $i = $begin; $i <= $end; $i++) {
        my $line = $template[$i];

        if ($line =~ /^\s*%%IF\b/) {
            $i = &PrintIf($i);  # point at %%ENDIF
            die "bounds error $begin/$i/$end\n" if ($i < $begin or $i > $end);
            next;               # bump pointer and continue
        }

        if ($line =~ /^\s*%%RANGE\b/) {
            my $begin2 = $i + 1;
            my $end2 = FindMatchingEndRange($begin2) - 1;
            if ($end2 >= $begin2) {
                &PrintRange($line, $begin2, $end2);
            }
            else {
                &Warn("empty or negative range block: $begin2 $end2\n");
            }
            $i = $end2 + 1;     # point at %%ENDRANGE
            next;               # bump pointer and continue
        }

        if ($line =~ /^\s*%%CSV\b/) {
            my $begin2 = $i + 1;
            my $end2 = FindMatchingEndCsv($begin2) - 1;
            if ($end2 >= $begin2) {
                &PrintCsv($line, $begin2, $end2);
            }
            else {
                &Warn("empty or negative csv block: $begin2 $end2\n");
            }
            $i = $end2 + 1;     # point at %%ENDCSV
            next;               # bump pointer and continue
        }

        if ($line =~ /^\s*%%BEGIN\b/) {
            my $begin2 = $i + 1;
            my $end2 = FindMatchingEnd($begin2) - 1;
            if ($end2 >= $begin2) {
                &PrintExpansion($begin2, $end2);
            }
            else {
                &Warn("empty or negative iteration block: $begin2 $end2\n");
            }
            $i = $end2 + 1;     # point at %%END
            next;               # bump pointer and continue
        }

        if ($line =~ /^\s*%%CAT\b/) {
            &Cat($template[$i]);
            next;
        }

        &Echo($template[$i]);
    }
}

# ------------------------------------------------------------------

# get the template

if ($#ARGV < 0) {
    die "usage: expand-template.pl [--debug] templatefile < dataset\n"
}

if ($ARGV[0] eq '--debug') {
    $debug = 1;
    shift(@ARGV);
}

$template = $ARGV[0];

open(TEMPLATE, $template) or die "open: $template: $!\n";
@template = <TEMPLATE>; # DO NOT CHOMP
close(TEMPLATE);

# expand the template
my $include_flag;
my $include_count = 0;
do {
    if ($include_count > 50) {
        die "$0: too many includes. infinite loop?\n";
    }
    $include_flag = 0;
    my @new_template = ();
    foreach my $line (@template) {
        if ($line !~ /^\s*%%INCLUDE\b/) {
            push(@new_template, $line);
            next;
        }
        &Warn("processing include: $line\n");
        $include_flag++;
        $include_count++;
        my @include_body = &Slurp($line);
        push(@new_template, @include_body);
    }
    @template = @new_template; # swap
} while ($include_flag > 0);

# ------------------------------------------------------------------

# get the dataset to work on

chomp(@dataset = <STDIN>);

# ------------------------------------------------------------------

# print the results
&PrintBlock(0, $#template);

# ------------------------------------------------------------------

&Warn("symbol dump:\n");
foreach $v (sort keys %used) {
    &Warn("$v\n");
}

# ------------------------------------------------------------------

exit 0;
