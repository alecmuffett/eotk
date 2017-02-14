#!/usr/bin/perl

my %data = (); # $data{$project}{$master_onion}{$worker_onion} = 1;
my %dnsmap = (); # $dnsmap{$master_onion} = $dns_domain

#------------------------------------------------------------------

sub SetEnv { # copied from do-configure.pl
    my ($var, $val, $why) = @_;
    die "bad varname: $var\n" if ($var !~ /^[A-Za-z_]\w+/);
    $var =~ tr/a-z/A-Z/;
    $ENV{$var} = $val;
    warn (($why ? "($why) " : "") . "set $var to $val\n");
}

sub Pipeify { # copied from do-configure.pl
    my ($cmd, @hashreflist) = @_; # there WILL be shell syntax in $cmd
    warn "Pipeify $cmd ...\n";

    my $first = $hashreflist[0];

    if (!defined($first)) {
        warn "Pipeify note: empty template\n";
    }

    my @vars = sort keys %{$first}; # get column names, assume uniformity

    open(PIPE, "|$cmd") or die "popen: $cmd: $!\n";
    warn "head @vars\n";
    print PIPE join(" ", @vars), "\n"; # send the column names, even if "empty"

    foreach my $hashref (@hashreflist) { # send the rows
        my @row = ();
        foreach my $var (@vars) {
            my $val = ${$hashref}{$var};
            die "Pipeify: empty var $var\n" unless ($val ne "");
            die "Pipeify: whitespace var $var: $val\n" if ($val =~ /\s/);
            push(@row, $val);
        }
        warn "body @row\n";
        print PIPE join(" ", @row), "\n";
    }
    close(PIPE) or die "pclose: $cmd: $!\n";
}

#------------------------------------------------------------------

while (<DATA>) {
    my ($project,
        $softmap,
        $master_onion,
        $dns_domain,
        $via,
        $worker_onion) = split(" ");
    die "bad format: not softmap: @x\n" if $softmap ne "softmap";
    die "bad format: not via: @x\n" if $via ne "via";
    $data{$project}{$master_onion}{$worker_onion} = 1;
    $dnsmap{$master_onion} = $dns_domain};
}

foreach my $project (sort keys %data) {
    foreach my $master_onion (sort keys %{$data{$project}}) {
        my @worker_onions = sort keys %{$data{$project}{$master_onion}};
        print "$project $master_onion : @worker_onions\n";
    }
}

__DATA__;
wiki softmap xlgm4owgbdusgwax.onion wikipedia.org via w7ghprgn4f4wbq7s.onion
wiki softmap 5xnr2xpxmxfd33qf.onion mediawiki.org via w7ghprgn4f4wbq7s.onion
wiki softmap geax5tb7xnejbxdo.onion wikibooks.org via w7ghprgn4f4wbq7s.onion
wiki softmap rkfvf6ijdrbzz7d7.onion wikidata.org via w7ghprgn4f4wbq7s.onion
wiki softmap nxmlavaypnu43ken.onion wikimedia.org via w7ghprgn4f4wbq7s.onion
wiki softmap rdqzpxkz3wnfdoz6.onion wikinews.org via w7ghprgn4f4wbq7s.onion
wiki softmap s5mzdqhesw5mzf67.onion wikiquote.org via w7ghprgn4f4wbq7s.onion
wiki softmap tqlvl34m5hcptes5.onion wikisource.org via w7ghprgn4f4wbq7s.onion
wiki softmap 7xddhe42phangeso.onion wikiversity.org via w7ghprgn4f4wbq7s.onion
wiki softmap xj62n2madibvnvtw.onion wikivoyage.org via w7ghprgn4f4wbq7s.onion
wiki softmap ejbhfdo3sww6j5ir.onion wiktionary.org via w7ghprgn4f4wbq7s.onion
wiki softmap xlgm4owgbdusgwax.onion wikipedia.org via zh63f4p2hev44a5b.onion
wiki softmap 5xnr2xpxmxfd33qf.onion mediawiki.org via zh63f4p2hev44a5b.onion
wiki softmap geax5tb7xnejbxdo.onion wikibooks.org via zh63f4p2hev44a5b.onion
wiki softmap rkfvf6ijdrbzz7d7.onion wikidata.org via zh63f4p2hev44a5b.onion
wiki softmap nxmlavaypnu43ken.onion wikimedia.org via zh63f4p2hev44a5b.onion
wiki softmap rdqzpxkz3wnfdoz6.onion wikinews.org via zh63f4p2hev44a5b.onion
wiki softmap s5mzdqhesw5mzf67.onion wikiquote.org via zh63f4p2hev44a5b.onion
wiki softmap tqlvl34m5hcptes5.onion wikisource.org via zh63f4p2hev44a5b.onion
wiki softmap 7xddhe42phangeso.onion wikiversity.org via zh63f4p2hev44a5b.onion
wiki softmap xj62n2madibvnvtw.onion wikivoyage.org via zh63f4p2hev44a5b.onion
wiki softmap ejbhfdo3sww6j5ir.onion wiktionary.org via zh63f4p2hev44a5b.onion
wiki softmap xlgm4owgbdusgwax.onion wikipedia.org via c7id3gyjb5t7n4uh.onion
wiki softmap 5xnr2xpxmxfd33qf.onion mediawiki.org via c7id3gyjb5t7n4uh.onion
wiki softmap geax5tb7xnejbxdo.onion wikibooks.org via c7id3gyjb5t7n4uh.onion
wiki softmap rkfvf6ijdrbzz7d7.onion wikidata.org via c7id3gyjb5t7n4uh.onion
wiki softmap nxmlavaypnu43ken.onion wikimedia.org via c7id3gyjb5t7n4uh.onion
wiki softmap rdqzpxkz3wnfdoz6.onion wikinews.org via c7id3gyjb5t7n4uh.onion
wiki softmap s5mzdqhesw5mzf67.onion wikiquote.org via c7id3gyjb5t7n4uh.onion
wiki softmap tqlvl34m5hcptes5.onion wikisource.org via c7id3gyjb5t7n4uh.onion
wiki softmap 7xddhe42phangeso.onion wikiversity.org via c7id3gyjb5t7n4uh.onion
wiki softmap xj62n2madibvnvtw.onion wikivoyage.org via c7id3gyjb5t7n4uh.onion
wiki softmap ejbhfdo3sww6j5ir.onion wiktionary.org via c7id3gyjb5t7n4uh.onion
wiki softmap xlgm4owgbdusgwax.onion wikipedia.org via 72hcgfqjgnwtkzx5.onion
wiki softmap 5xnr2xpxmxfd33qf.onion mediawiki.org via 72hcgfqjgnwtkzx5.onion
wiki softmap geax5tb7xnejbxdo.onion wikibooks.org via 72hcgfqjgnwtkzx5.onion
wiki softmap rkfvf6ijdrbzz7d7.onion wikidata.org via 72hcgfqjgnwtkzx5.onion
wiki softmap nxmlavaypnu43ken.onion wikimedia.org via 72hcgfqjgnwtkzx5.onion
wiki softmap rdqzpxkz3wnfdoz6.onion wikinews.org via 72hcgfqjgnwtkzx5.onion
wiki softmap s5mzdqhesw5mzf67.onion wikiquote.org via 72hcgfqjgnwtkzx5.onion
wiki softmap tqlvl34m5hcptes5.onion wikisource.org via 72hcgfqjgnwtkzx5.onion
wiki softmap 7xddhe42phangeso.onion wikiversity.org via 72hcgfqjgnwtkzx5.onion
wiki softmap xj62n2madibvnvtw.onion wikivoyage.org via 72hcgfqjgnwtkzx5.onion
wiki softmap ejbhfdo3sww6j5ir.onion wiktionary.org via 72hcgfqjgnwtkzx5.onion
