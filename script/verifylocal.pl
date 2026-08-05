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

        my ( $type, $name ) =
          ( $line =~ /^(?:(warning|error): )?([^:]+):.*.$/ig );
        return undef if $type eq 'error';
        return undef unless $name;

        push @$dest, $name unless any { $name eq $_ } @$dest;
    };

    my $run = run(
        [ qw(pacman -Q ), ( $check_content ? '-s' : '-k' ) ],
        out       => sub ( $line, @ ) { $on_h->( $line, $dest{no_issue} ) },
        err       => sub ( $line, @ ) { $on_h->( $line, $dest{warning} ) },
        autochomp => 1
    );

    dmsg $run;

    \%dest;
}
use Data::Printer;
use TOML::Tiny 'to_toml';

my $local_pkg = verify_installed( shift @ARGV );
dmsg $local_pkg;
say to_toml( { warning => $local_pkg->{warning} } );
