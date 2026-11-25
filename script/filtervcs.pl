#!/usr/bin/env perl
package filtervcs;

use v5.44;
use IO::Handle::Common;
use List::Util 'uniq';

my @in   = @ARGV;
my %seen = ();
my @out;

foreach my $pkg (@in) {
    if ( my ($novcs) = ( $pkg =~ /^(.+)-git$/g ) ) {
        $seen{$novcs} = 1;
    }
    elsif ( !exists $seen{$pkg} ) { next }

    push @out, $pkg;
}

say join "\n", uniq grep { !$seen{$_} } $ENV{VCS_ONLY} ? @out : @in
