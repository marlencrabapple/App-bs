#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package App::BS::Repo;

class App::BS::Repo : does(App::BS::Package::Version);

use utf8;
use v5.44;

no warnings 'experimental::re_strict';
use re 'strict';

use builtin;
use Const::Fast;

field $bs_root : param //= $ENV{BS_ROOT};
field $root    : param //= $ENV{BS_REPOROOT};
field $name    : param //= $ENV{BS_REPO};
field $target  : param //= $ENV{BS_TARGET};
field $path    : param //= "$root/$name/os/$target";

method file_newest ( $pkgname, %opt ) {
    ($pkgname) = ARRAY($pkgname);

    foreach my $pkgname (@$pkgname) {
        my $fileptn = qr/^$pkgname-(.+).pkg.tar.zst$/;
        my @file;
        foreach my ( $prev, $curr, $next ) ( undef, $path->children($fileptn) )

          # {   (my ($version) =  ($file =~ $fileptn)) {
        {
            if ( my ($version) = ( $curr =~ $fileptn ) ) {
                $curr =
                  { name => $pkgname, version => $version, path => $curr };

                if ($prev) {
                    dmsg( vercmp( $$prev{version}, $$curr{version} ) );
                }
            }
            next;
        }
    }
}
