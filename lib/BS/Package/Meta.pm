use Object::Pad qw(:experimental(:all));

package BS::Package::Meta;
role BS::Package::Meta :does(BS::Common);

use utf8;
use v5.40;

use Struct::Dumb;
use Syntax::Keyword::MultiSub;

PkgDepends(qw(make optional check depends));
PkgChecksums(qw(ck md5 sha1 sha256 sha512 b2));

field $pkg :param;
field $pkgname :param;
field $pkgbase :param;
field $depends :param = undef;
field $pkgver :param = undef;
field $pkgrel :param = undef;
field $pkgdesc :param = undef;
field $url :param = undef;
field $changelog :param = undef;

field @license;
field @source;
field @validpgpkeys;
field @noextract;
field @groups;
field @arch;
field @backup;
field @conflicts;
field @replaces;
field @provides;

field $options = $pkg->env->{PKGBUILD_OPTIONS}
              // $pkg->env->{pkgbuild}{options};

field $checksums;

field $srcinfo;
field $srcinfo_path;

# field $depends = {
#   _ => [],
#   map { $_ . 'depends' => [] } qw(make opt check)
# };

# field $checksums = [
#   map { $_ . 'sums' => [] } qw(ck md5 sha1 sha256 sha512 b2)
# ];

method pkgstr ($pref = 'base') {
  state $pkgstr = { base => $pkgbase, name => $pkgname };
  delete $$pkgstr{$pref} // $pkgstr->[-1]
}

multi method srcinfo ($srcinfo) {
  $self->srcinfo unless $srcinfo
}

multi method srcinfo :common ($srcinfo = undef, %args) {

}