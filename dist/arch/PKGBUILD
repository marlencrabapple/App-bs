# Maintainer: Ian Bradley <crabapp@hikki.tech>
_pkgname=perl-app-bs
pkgname="$_pkgname-git"
_perl_namespace=App
_perl_module=BS
pkgver=0
pkgrel=2
pkgdesc="Build system for PKGBUILD based Linux distributions"
arch=(any)
license=('Artistic-1.0-Perl' 'GPL-1.0-or-later')
depends=('perl' 'expac' 'pacutils' 'archlinux-contrib' 'pacman-contrib'
  'archiso' 'pacman-mirrorlist' 'shiny-mirrors-git' 'perl-net-ssleay')
makedepends=('perl-syntax-keyword-try' 'perl-cpanel-json-xs'
  'perl-app-fatpacker' 'perl-module-build' 'perl-dbi' 'cpanminus' 'perl-inline-c'
  'perl-path-tiny' 'perl-net-ssleay')
options=('!emptydirs' 'staticlibs')
url="https://github.com/marlencrabapple/App-bs"
source=("git+$url.git")
b2sums=('SKIP')
sha513sum=('cd3937afa78831f80a2ad5abab6c51b9e82fca4c31e5856ea208d598db5dc867')
validpgpkeys=(5D8733704B740FC4B330EF5E8FFAD8B7BA73987)

prepare() {
  cd "$srcdir/App-bs"

  unset PERL5LIB PERL_MM_OPT PERL_MB_OPT PERL_LOCAL_LIB_ROOT

  export PERL5LIB="./local/lib/perl5"
  export PERL_CPANM_OPT="-L$(pwd)local \
   --verbose \
   --save-dists \
   --self-contained \
   --with-develop \
   --with-all-features"
}

build() {
  cd "$srcdir/App-bs"
  cpanm Net::SSLeay --notest
  cpanm --installdeps .
  perl Build.PL
  ./Build build
}

check() {
  cd "$srcdir/App-bs"
  ./Build testall
}

package() {
  cd "$srcdir/App-bs"
  INSTALL_BASE=/usr ./Build install --destdir "$pkgdir"
}
