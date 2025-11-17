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
_commit=c874288b9222771bd063a52b697b0f5119a59720
source=("$_pkgname::git+$url#commit=$_commit")
sha512sums=('5cb3084bce576c5885ecfc1308916b1d321c2fbfaa3314a421302498c87946dfbe62b2628108177ce14c4354614ff5644cbd19c09e2954beebbd7333f12146d5')
b2sums=('ff8e87a2a12743d7ea1b9425ac9854fab0c2ddbc5499e5aa5ca6e02d491928259c9e6a688773955bf6a8550a7616f31d75a811da4ac29b198f5d41d707c9706b')

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
