#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package App::BS::Ext::pactree;

role App::BS::Ext::pactree
  : does(App::BS::Ext::Common)
  : does(App::BS::Run);

use utf8;
use v5.44;

no warnings 'experimental::re_strict';
use re 'strict';

use List::Util qw'uniq none';
use IO::Handle::Common;

field $depth : param = undef;

method pactree ( $pkglist, %opt ) {
    my @res = ();

    my $dest = $opt{dest} //= { pkg => [], file => [] };
    $opt{db} //= 'sync';
    ($pkglist) = App::BS::Common::ARRAY($pkglist);

    my @pkgname = ();
    my @file    = ();

    foreach my $pkgstr (@$pkglist) {
        my @cmd = (
            qw(pactree -lu --config),
            $self->pacman_conf, ( $opt{db} eq 'sync' ? qw'-s' : () )
        );

        push @cmd, ( '--depth', $depth ) if defined $depth;

        my $run = $self->run(
            [ @cmd, $pkgstr ],
            out => sub ( $line, @ ) {

                if ( my ( $soname, $sover ) =
                    $line =~ $App::BS::Ext::Common::soname_re )
                {
                    push @file, $soname
                      if none { $_ eq $soname } @file, $$dest{file}->@*;
                }
                elsif ( my ( $name, $cmp, $ver ) =
                    $line =~ $App::BS::Ext::Common::pkgname_re )
                {
                    push @pkgname, $name
                      if none { $_ eq $name } @pkgname, $$dest{pkg}->@*;
                }
                else {
                    error
"'$pkgstr' does not seem to be a shared object or package name/base.";
                }
            }
        );
        push @res, $run;
    }

    push $$dest{pkg}->@*, uniq $self->pacman_pkgname( \@pkgname )
      if scalar @pkgname;    #$$dest{pkg}->@*;

    push $$dest{pkg}->@*, uniq $self->pacman_files( \@file )
      if scalar @file;

    $opt{dest}->%*;
}
