use Object::Pad;

package BS::Package::Meta;
role BS::Package::Meta :does(BS::Common);

use utf8;
use v5.40;

use Data::Printer;
use Struct::Dumb;

#use BS::Package;
use BS::Ext::pacsift;

use constant VALID_PKG_RE_CCLASS_START => "a-z0-9\@_\+";
use constant VALID_PKG_RE_NB => qr/[${\VALID_PKG_RE_CCLASS_START}]{1}[${\VALID_PKG_RE_CCLASS_START}\.\-]+(\.so)|[${\VALID_PKG_RE_CCLASS_START}]{1}[${\VALID_PKG_RE_CCLASS_START}\.\-]+/;

struct PkgDepends => [qw(make optional check depends)];
struct PkgChecksums => [qw(ck md5 sha1 sha256 sha512 b2)];

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

field $options

field $checksums;

field $srcinfo;
field $srcinfo_path;

method parse_dep :common ($line, %args) {
  use constant PACINFO_SO_PREFIX => qr/(?:lib\:)?/;
  use constant DEP_SO_RE => qr/\.so/;
  use constant VALID_DEPIDEN_RE => qr/${\PACINFO_SO_PREFIX}(${\VALID_PKG_RE_NB})(?:${\DEP_SO_RE})?/;
  use constant DEP_ATTRSEP_RE => qr/(?:\=)|(?:[\<\>]\=?)|(?:(?:\:))|(?:\.)/;  
  use constant DEP_ATTR_RE => qr/^${\VALID_DEPIDEN_RE}(?:\s*(${\DEP_ATTRSEP_RE})\s*(.+))?\n$/;
  
  my ($depname, $soext, $sep, $attr) = $line =~ DEP_ATTR_RE;
  my %dep_pkgargs = ();

  $dep_pkgargs{name} = $depname;

  if ($sep) {
    if ($sep ne ':') {
      $dep_pkgargs{version} = $attr;
      $dep_pkgargs{cmp_op} = $sep;
      $dep_pkgargs{file} = $depname if $soext
    }
    elsif ($sep eq ':') { # Optional dependency most likely
                          # Will have parsed that out elsewhere
      $dep_pkgargs{description} = $attr;
      $dep_pkgargs{name} = $depname
    }
  }

  if ($soext) {
    my @fquery_args = qw(-Fq);
    my $now = time;
    state $fdbsync = $now;

    # TODO: Track "top level" package progress and time since last refresh
    # to reset this in addition to resetting per run
    if ($args{sync} || ($now == $fdbsync)) {
      push @fquery_args, qw(-y -y)
    }

    $dep_pkgargs{file} //= $depname;
    my @out = ();
    my $res =  BS::Common->bsx([qw(sudo pacman), @fquery_args, $dep_pkgargs{file}], in => undef, out => \@out);

    my $match = $res->out->[-1];
    chomp $match;

    ($dep_pkgargs{repo}, $dep_pkgargs{name}) = (split '/', $match)
  }
  
  \%dep_pkgargs
}