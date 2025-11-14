# Maintainer: Ian Bradley <crabapp@hikki.tech>
_pkgname=perl-app-bs
pkgname="$_pkgname-git"
_perl_namespace=App
_perl_module=BS
pkgver=app.bs.0.r1.r3.gb47116d
pkgrel=1
pkgdesc="Build system for PKGBUILD based Linux distributions"
arch=(any)
license=('Artistic-1.0-Perl' 'GPL-1.0-or-later')
depends=('perl' 'expac' 'pacutils' 'archlinux-contrib' 'pacman-contrib'
  'archiso' 'pacman-mirrorlist' 'shiny-mirrors-git' 'perl-net-ssleay'
  'perl-devel-checkbin')
makedepends=('perl-syntax-keyword-try' 'perl-cpanel-json-xs'
  'perl-app-fatpacker' 'perl-module-build' 'perl-dbi' 'cpanminus'
  'perl-inline-c' 'perl-path-tiny' 'perl-net-ssleay' 'perl-module-build-xsutil')
options=('!emptydirs' 'staticlibs')
url="https://cincotuf.lan/pennylinux/BS"
_commit=5dbb4356dbc83f9e3a5f83f945030baf58d7953c
source=("$_pkgname::git+$url#commit=$_commit")
sha512sums=('ce723231eb9a9b1051f4211736c57e5dba90e77839e8c66876143206d4fa43de3968d9c1f78c3ef461aaf70f7b9d35fff7f3a7aa387fa3704266a600263c0f92')
b2sums=('5e3106d24b2052790fabc825231de7fccf92719fb96257c0f634dbdd20b5872d0c105f4f6d16400bbfdbe2d03506639e1f5d763c2e26ab724c9176fdca54122a')

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
  INSTALL_BASE=/usr ./Build install --destdir "$pkgdir"
}
