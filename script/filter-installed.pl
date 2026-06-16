#!/usr/bin/env perl

package FilterInstalled;

use utf8;
use v5.40;

use lib 'lib';

use Getopt::Long;
use IO::Handle::Common;
use IPC::Nosh;
use List::Util qw'none any';

sub filter_installed {
    my @installed;
    my %seen;

    my $addpkg = sub ( $pkg, %opt ) {
        push @installed, $pkg if none { $pkg eq $_ } @installed;
        $seen{$pkg} //= 0;
        $seen{$pkg}++;
    };

    my $run = run(
        [qw(pacman -Qneq)],
        out       => sub ( $line, @ ) { $addpkg->($line) },
        autochomp => 1
    );

    # my @installed = map { chomp $_; $_ } `pacman -Qneq`;
    # my %seen      = map { ( $_ => 1 ) } @installed;

    foreach my $pkg (@ARGV) {
        $seen{$pkg}++ if $seen{$pkg};
        dmsg $pkg, $seen{$pkg};
    }

    if (-t <>) {
        foreach my $pkg (map { chomp $_; $_ } (<STDIN>)) {
            $addpkg->($pkg)
        }
    }

    say join " ", grep { $seen{$_} > 1 } keys %seen;
}

filter_installed()
