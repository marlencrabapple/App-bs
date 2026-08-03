#!/usr/bin/env perl

package App::bs::brokenfiles;

use utf8;
use v5.42;

use List::Util qw'any none uniq';
use IPC::Nosh;
use IO::Handle::Common;

#  sub verify_installed ( $check_content = 0 ) {
#     my @pkgname = ();
#     my $run     = run(
#         [ qw(pacman -Q), ( $check_content ? '-s' : '-k' ) ],
#         out => sub ( $line, @ ) {
#             my ($errtype, $me) = ( $line =~ /^(?:(warning|[^:]+): )?([^:]+):.*.$/igx );
#             return undef unless $name;

#             push @pkgname, $name unless any { $name eq $_ } @pkgname;
#         }
#     );
#     $App::bs::brokenfiles::run = $run ;
#     @pkgname;
# }

sub verify_installed ( $check_content = 0 ) {
    my %dest = ( warning => [], no_issue => [] );
    my $on_h = sub ( $line, $dest ) {

        my ($name) = ( $line =~ /^(?:warning: )?([^:]+):.*.$/igx );
        return undef unless $name;

        push @$dest, $name unless any { $name eq $_ } @$dest;
    };

    my $run = run(
        [ qw(pacman -Q), ( $check_content ? '-s' : '-k' ) ],
        out       => sub ( $line, @ ) { $oh_h->($f) },
        err       => sub ( $line, @ ) { $oh_h->($f) },
        autochomp => 1
    );

    dmsg $run;

    @pkgname;
}
