#!/usr/bin/perl -w
# eotk (c) 2017 Alec Muffett

use Data::Dumper;

my $debug = 0;
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

    die "lookup: $var not set\n";
}

sub Echo {
    &Warn("Echo1 @_");
    my $line = shift;
    if ($line =~ /%/) {
	$line =~ s/%([\w+]+)%/&Lookup($1)/ge;
    }
    &Warn("Echo2 $line");
    print $line;
}

sub PrintExpansion {
    my ($begin, $end) = @_; # inclusive

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
    &Warn("scope $#scopes popped\n");
}

sub PrintRange {
    my ($line, $begin, $end) = @_;

    &Warn("range begin: $begin $template[$begin]");
    &Warn("range end: $end $template[$end]");

    # limits
    $line =~ s/%([\w+]+)%/&Lookup($1)/ge;
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
    &Warn("scope $#scopes popped\n");
}

sub FindMatchingEnd {
    my $i = shift;
    my $nestlevel = 0;
    &Warn("looking for %%END starting from $i $template[$i]");
    for (undef; $i <= $#template; $i++) {
        if ($template[$i] =~ /^\s*%%BEGIN\b/) {
            $nestlevel++;
            next;
        }
        if ($template[$i] =~ /^\s*%%END\b/) {
            if ($nestlevel > 0) {
                &Warn("found nested($nestlevel) %%END at $i $template[$i]");
                $nestlevel--;
                next;
            }
            &Warn("found %%END at $i $template[$i]");
            return $i;
        }
    }
    die "runaway search for %%END\n";
}

sub FindMatchingEndRange { # yes it's cut and paste, no i don't care yet
    my $i = shift;
    my $nestlevel = 0;
    &Warn("looking for %%ENDRANGE starting from $i $template[$i]");
    for (undef; $i <= $#template; $i++) {
        if ($template[$i] =~ /^\s*%%RANGE\b/) {
            $nestlevel++;
            next;
        }
        if ($template[$i] =~ /^\s*%%ENDRANGE\b/) {
            if ($nestlevel > 0) {
                &Warn("found nested($nestlevel) %%ENDRANGE at $i $template[$i]");
                $nestlevel--;
                next;
            }
            &Warn("found %%ENDRANGE at $i $template[$i]");
            return $i;
        }
    }
    die "runaway search for %%ENDRANGE\n";
}

sub PrintIf { # having %%ELSE makes this a little more complex
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

    $cond =~ s/%([\w+]+)%/&Lookup($1)/ge;
    &Warn("evaluate: $cond");

    my $result = (split(" ", $cond))[1];
    die "bad conditional: $template[$start]\n" if (!defined($result));
    &Warn("result: $result\n");

    if ($result) { # true
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

sub PrintBlock {
    my ($begin, $end) = @_; # inclusive

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
	    $i = &PrintIf($i); # point at %%ENDIF
	    die "bounds error $begin/$i/$end\n" if ($i < $begin or $i > $end);
	    next; # bump pointer and continue
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
	    $i = $end2 + 1; # point at %%ENDRANGE
	    next; # bump pointer and continue
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
	    $i = $end2 + 1; # point at %%END
	    next; # bump pointer and continue
	}

	&Echo($template[$i]);
    }
}

# ------------------------------------------------------------------

# get the template

if ($ARGV[0] eq '--debug') {
    $debug = 1;
    shift(@ARGV);
}

if ($#ARGV < 0) {
    die "usage: expand-template.pl template.txt < dataset\n"
}
else {
    $template = $ARGV[0];
}

open(TEMPLATE, $template) or die "open: $template: $!\n";
@template = <TEMPLATE>; # DO NOT CHOMP
close(TEMPLATE);

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
