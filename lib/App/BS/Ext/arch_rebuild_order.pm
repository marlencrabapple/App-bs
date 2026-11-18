#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package App::BS::Ext::arch_rebuild_order;

role App::BS::Ext::arch_rebuild_order
  : does(App::BS::Ext::Common)
  : does(App::BS::Run);

use utf8;
use v5.44;

no warnings 'experimental::re_strict';
use re 'strict';

use builtin;
use List::Util qw'uniq none';
use IO::Handle::Common;
use Syntax::Keyword::Dynamically;

field $reversedeps = false;

method arch_rebuild_order( $pkgname_aref, %opt ) {
    my $ordered = $opt{dest} // [];
    my $repostr = '--repos=' . join ',',
      (
          $opt{repo} && refstr( $opt{repo} ) eq 'ARRAY'
        ? $opt{repo}->@*
        : keys $self->repolist->%*
      );

    dynamically $reversedeps = $opt{reversedeps} if $opt{reversedeps};

    my $run = $self->run(
        [
            qw'arch-rebuild-order',                         $repostr,
            ( $reversedeps ? () : '--no-reverse-depends' ), @$pkgname_aref
        ],
        out => sub ( $line, @ ) {
            push @$ordered, split /\s/, $line;
        },

        # autochomp => 1
    );

    @$ordered;
}
