#!/usr/bin/env perl

package asdfsadf;

use v5.40;
use Const::Fast;
use List::Util;
use IPC::Nosh;

my @sharedlib  = ();
my %byname     = ();
my %byrepo     = ();
my @pacman_arg = qw(-F -q -y);

sub search_filedb( $so, %opt ) {

    my $run = run(
        [ 'pacman', @pacman_arg, $so ],
        out => sub( $line, @ ) {
            my ( $repo, $pkgname ) = ( $line =~ m!([^/]+)/(.+)!gx );

            say " - $repo/$pkgname";

            $byname{$pkgname} //= 0;
            $byname{$pkgname}++;

            $byrepo{$pkgname} //= [];

            push $byrepo{$pkgname}->@*, $pkgname;

            pop @pacman_arg if scalar @pacman_arg == 3;
        }
    );
}

sub pkgbase ( $pkgname, %opt ) {
    run( [qw'pacman -Sqs '] );
    ...;
}

sub so2pkgmeta ( $so, %opt ) {
    foreach my ($so) (@ARGV) {
        say "$so:";
        search_filedb($so);

    }
}

sub ldd_out ($binpath) {

    const my $lddline_re => qr!^[\s\t]*
      ([^\s]+) => ([^\s]+)? \(?:0x[0-9a-z]+\)
    $!x;

    my $run = run(
        [ 'ldd', $binpath ],
        out => sub ( $line, @ ) {
            if ( my ( $basename, $path ) = $line =~ $lddline_re ) {

                push @sharedlib, { basename => $basename, path => $path };
            }
        }
    );
}
