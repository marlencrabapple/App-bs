# Maintainer: Ian Bradley <crabapp@hikki.tech>
_pkgname=perl-app-bs
pkgname="$_pkgname-git"
_perl_namespace=App
_perl_module=BS
pkgver=0.0.1.r0.g69d0938
pkgrel=2
pkgdesc="Build system for PKGBUILD based Linux distributions"
arch=(any)
license=('Artistic-1.0-Perl' 'GPL-1.0-or-later')
depends=('perl' 'expac' 'pacutils' 'archlinux-contrib' 'pacman-contrib'
  'archiso' 'pacman-mirrorlist' 'shiny-mirrors-git' 'perl-net-ssleay'
  'perl-devel-checkbin' 'arch-rebuild-order')
makedepends=('perl-syntax-keyword-try' 'perl-cpanel-json-xs'
  'perl-app-fatpacker' 'perl-module-build' 'perl-dbi' 'cpanminus'
  'perl-inline-c' 'perl-path-tiny' 'perl-net-ssleay' 'perl-module-build-xsutil')
options=('!emptydirs' 'staticlibs')
url="https://cincotuf.lan/pennylinux/BS"
_commit=69d0938468d1432c6ed513081fb87178210abc90
source=("$_pkgname::git+$url#commit=$_commit")
sha512sums=('da9d0a455bdf0cacd8e5a747552d92696ebe9199a0800da15a58ebf2dd242ffadbb10c388e44dd31720186590d71895d4640ba0f48f790e35d3e112f2bcb158d')
b2sums=('d2c00013242f1e9ae73720d4245b788b746941466a58466a0c64bf7e48bb2722fba23aacb4e2f64b00b10e762396c3cf8d7d31c7b8950b86a93410f566f75784')

pkgver() {
  cd "$srcdir/$_pkgname"
  (
    set -o pipefail
    git describe --long --abbrev=7 2>/dev/null | sed 's/\([^-]*-g\)/r\1/;s/-/./g' ||
      printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short=7 HEAD)"
  )
}

prepare() {
  cd "$srcdir/$_pkgname"

  unset PERL5LIB PERL_MM_OPT PERL_MB_OPT PERL_LOCAL_LIB_ROOT

  export PERL5LIB="$(pwd)/local/lib/perl5"
  export PERL_CPANM_OPT="-L$(pwd)/local \
   --save-dists . \
   --self-contained \
   --with-develop \
   --with-configure \
   --verify \
   --with-all-features"
}

build() {
  cd "$srcdir/$_pkgname"
  cpanm Net::SSLeay --notest
  cpanm --installdeps .
  perl Build.PL
  ./Build build
}

check() {
  cd "$srcdir/$_pkgname"
  ./Build testall
}

package() {
  cd "$srcdir/$_pkgname"
  ./Build install \
   --destdir="$pkgdir" \
   --install_base=/usr \
   --prefix=/usr \
   --verbose
}
