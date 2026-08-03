#!/usr/bin/env perl

use Object::Pad qw(:experimental(:all));

package BS::pkgstrparse;

class BS::pkgstrparse;

use utf8;
use v5.40;

no warnings 'experimental';
use re 'strict';

use List::Util qw'any uniq';
use Const::Fast;
use IO::Handle::Common::Handle;

# my %parsed = map {
#     my %parsed = ();
#     @parsed{qw'name epoch ver rel arch ext'} =
#       ( $_ =~
# /^([^.-]{1}[a-z0-9@_+.-]+)(:[0-9]+)?-([^\s:-]+)-([0-9]+)-(any|aarch64|i368|i638|(?:x86_64(?:_v3)?))\.(pkg\.tar\.(?:zst|xz|gz|bz2|zip))$/ig
#       );
#     ( $_ => \%parsed );
# } @found;

const our $pkgname_common_re => qr'[^.-]{1}[a-z0-9@_+.-]+?'xi;
const our $pkgstr_re         => qr/($pkgname_common_re)/xi;

const our $epoch_re  => qr'([0-9]+):'xi;
const our $pkgver_re => qr'([^\s:-]+?)'xi;
const our $pkgrel_re => qr'([0-9]+)'xi;

const our $arch_re   => qr'(any|aarch64|i368|i638|(?:x86_64(?:_v3)?))'xi;
const our $pkgext_re => qr'(pkg\.tar\.(?:zst|xz|gz|bz2|zip))'xi;

const our $pkgfile_re => qr'$pkgstr_re
                            -($epoch_re:)?
                            $pkgver_re-$pkgrel_re
	               		    -$arch_re
			                \.$pkgext_re
			               'xxi;

const our $pkgspec_re => qr'$pkgstr_re
                            -($epoch_re:)?
                            $pkgver_re-$pkgrel_re
	               		    -$arch_re
			               'xxi;

method parse_pkg_fname : common ($pkgfile) {
    my @match = ( $pkgfile =~ $pkgfile_re );
    dmsg( $pkgfile, @match );
    @match;
}

method parse_pkgspec : common ($pkgstr) {
    my @match = ( $pkgstr =~ /^$pkgspec_re$/ );
    my ( $pkgnomer, $epoch, $pkgver, $pkgrel, $arch, @extra ) = @match;

    dmsg( $pkgstr, $pkgnomer, $epoch, $pkgver, $pkgrel, $arch, @extra );

    @match;
}

package main;

use utf8;
use v5.40;

use Path::Tiny;
use IPC::Nosh::Common;

my @match;

push @match, BS::pkgstrparse->parse_pkgspec($_) for map {
    my $path     = path($_);
    my $basename = $path->basename;
    my $noext    = $basename =~ s/(.+)\.pkg\.tar\.zst$/$1/r;
    dmsg( $_, $path, $basename, $noext );
    $noext
} @ARGV;

dmsg(@match);

say $match[0]
