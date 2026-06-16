#!/usr/bin/env perl

package FilterInstalled;

use utf8;
use v5.40;

use lib 'lib';

use Getopt::Long qw(GetOptionsFromArray :config no_ignore_case);
use IO::Handle::Common;
use IPC::Nosh;
use List::Util qw'none any';

our @inpkg     = ();
our @installed = ();
our %seen      = ();

sub add_pkg ( $pkg, %opt ) {
    $seen{$pkg} //= 0;
    $seen{$pkg}++;
}

sub cli ( $argv //= \@ARGV, %opt ) {
    my %cliopt = ( in => \@inpkg );

    GetOptionsFromArray(
        $argv,
        \%cliopt,
        'debug+',
        'verbose+',
        'explicit!',
        '<>' => sub ($barearg) {
            add_pkg($barearg);
            push @inpkg, $barearg if none { $barearg eq $_ } @inpkg;
        }
    );

    if ( !-t STDIN ) {
        foreach my $pkg ( map { chomp $_; $_ } (<STDIN>) ) {
            dmsg $pkg;
            add_pkg($pkg);
            push @inpkg, $pkg if none { $pkg eq $_ } @inpkg;
        }
    }
}

sub filter_installed {
    my $run = run(
        [qw(pacman -Qneq)],
        out => sub ( $pkg, @ ) {
            push @installed, $pkg if none { $pkg eq $_ } @installed;
            add_pkg($pkg);
            say $pkg if $seen{$pkg} > 1;
          },
        autochomp => 1
    );

    say join " ", grep { $seen{$_} > 1 } keys %seen;
}


cli( \@ARGV );
filter_installed()
