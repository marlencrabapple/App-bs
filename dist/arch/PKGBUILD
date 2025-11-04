# Maintainer: Ian Bradley <crabapp@hikki.tech>
_pkgname=perl-app-bs
pkgname="$_pkgname-git"
_perl_namespace=App
_perl_module=BS
pkgver=r100.fd1fc4b
pkgrel=1
pkgdesc="Build system for PKGBUILD based Linux distributions"
arch=(any)
license=('Artistic-1.0-Perl' 'GPL-1.0-or-later')
depends=('perl' 'expac' 'pacutils' 'archlinux-contrib' 'pacman-contrib'
  'archiso' 'pacman-mirrorlist' 'shiny-mirrors-git' 'perl-net-ssleay')
makedepends=('perl-syntax-keyword-try' 'perl-cpanel-json-xs'
  'perl-app-fatpacker' 'perl-module-build' 'perl-dbi' 'cpanminus'
  'perl-inline-c' 'perl-path-tiny' 'perl-net-ssleay')
options=('!emptydirs' 'staticlibs')
url="https://github.com/marlencrabapple/App-bs"
_commit=fd1fc4b2110df47fc3a76dbe052864943d8908dd
source=("git+$url.git#commit=$_commit")
b2sums=('b83af2b1274a963c3c4d174f282a0673c28a3e4ab7c715686c12d87f7d30d8038254be0cee7cf1632c1b4df379284ef30579b9045a2e993a373baac0b090cb97')
sha513sum=('cd3937afa78831f80a2ad5abab6c51b9e82fca4c31e5856ea208d598db5dc867')
validpgpkeys=(5D8733704B740FC4B330EF5E8FFAD8B7BA73987)

pkgver() {
  cd "$srcdir/App-bs"
  (
    set -o pipefail
    git describe --long --abbrev=7 2>/dev/null | sed 's/\([^-]*-g\)/r\1/;s/-/./g' ||
      printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short=7 HEAD)"
  )
}

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
