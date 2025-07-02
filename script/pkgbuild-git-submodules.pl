#!/usr/bin/env perl

package BS::pkgbuild::git::Submodules;

use utf8;
use v5.40;

use Cwd qw(abs_path cwd);

my $smpath = abs_path( $ARGV[0] && -d $ARGV[0] ? $ARGV[0] : '.' );

sub submodule_gen_prepare ( $path //= cwd ) {
    $path = abs_path($path);
}

sub submodule_gen_source ( $path //= cwd ) {
    $path = abs_path($path);
}
