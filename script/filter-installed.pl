#!/usr/bin/env perl

package FilterInstalled;

use utf8;
use v5.40;

use lib 'lib';

use BS::Common;

BS::Common::dmsg(
    {
        filter_installed => \%FilterInstalled::,
        main             => \%main::
    }
);

sub run {
    my @installed = map { chomp $_; $_ } `pacman -Qneq`;
    my %seen      = map { ( $_ => 1 ) } @installed;

    BS::Common::dmsg(
        {
            filter_installed => \%FilterInstalled::,
            main             => \%main::
        }
    );

    foreach my $pkg (@ARGV) {
        $seen{$pkg}++ if $seen{$pkg};
        BS::Common::dmsg( { pkg => $pkg, "\$seen{$pkg}" => $seen{$pkg} } );
    }

    BS::Common::dmsg(
        {
            '@ARGV'   => \@ARGV,
            installed => \@installed,
            seen      => \%seen
        }
    );

    say join " ", grep { $seen{$_} > 1 } keys %seen;
}

run()
