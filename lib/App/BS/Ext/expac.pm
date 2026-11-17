#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package App::BS::Ext::expac;

role App::BS::Ext::expac
  : does(App::BS::Ext::Common)
  : does(App::BS::Run);

use utf8;
use v5.44;

no warnings 'experimental::re_strict';
use re 'strict';

use List::Util qw'uniq none';

method pkgfield ( $pkgin, $field, %opt ) {
    my $op = '-S';
    $op .= 's' unless $opt{exact};

    ( $pkgin, $field, $opt{dest} ) =
      App::BS::Common::ARRAY( $pkgin, $field, $opt{dest} );

    my @cmd = (
        'expac', $op,
        ( join ',', uniq @App::BS::Ext::Common::FIELD_MAP{@$field} )
    );

    my $outh = sub ( $line, @ ) {
        push $opt{dest}->@*, grep {
            my $new = $_;
            none { $_ eq $new } $opt{dest}->@*
        } split /\s/, $line;
    };

    my $run;

    if ( $opt{exact} ) {
        $run = $self->run( [ @cmd, @$pkgin ], out => $outh );
    }
    else {
        foreach my $pkgstr (@$pkgin) {
            $self->run( [ @cmd, $pkgstr ], out => $outh );
        }
    }

    $opt{dest}->@*;
}
