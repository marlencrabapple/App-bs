use Object::Pad qw(:experimental(:all));

package BS::Package::Meta;
role BS::Package::Meta :does(BS::Common);

use utf8;
use v5.40;

use Data::Printer;
use Struct::Dumb;
use Syntax::Keyword::MultiSub;

use constant VALID_PKG_RE_CCLASS_START => "a-z0-9\@_\+";
use constant VALID_PKG_RE_NB => qr/[${\VALID_PKG_RE_CCLASS_START}]{1}[${\VALID_PKG_RE_CCLASS_START}\.\-]+/;

struct PkgDepends => [qw(make optional check depends)];
struct PkgChecksums => [qw(ck md5 sha1 sha256 sha512 b2)];

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

# method pkgstr ($pref = 'base') {
#   state $pkgstr = { base => $pkgbase, name => $pkgname };
#   delete $$pkgstr{$pref} // $pkgstr->[-1]
# }

multi method from_srcinfo :common ($srcinfo = undef, %args) {
  if(ref $srcinfo eq 'ARRAY') {

  }
  elsif (ref $srcinfo eq 'Path::Tiny') {

  }
  elsif (defined $srcinfo) {

  }

  if (-e $srcinfo) {
    $srcinfo = path($srcinfo) unless ref $srcinfo eq 'Path::Tiny'
  }
  else {
    #my $srcinfo_ashref = ...
  }
}

method srcinfo_ashref () {
  my %srcinfo = ();
  #my $srcinfostr = $
  # while (my $line = ) {
   
  # }

  return \%srcinfo
}

method srcinfo_deps :common ($file) {
  my @deps = ();
  foreach my $line (path($file)->lines_utf8) {

  }
}

method srcinfo_parsestr :common ($str) {
  my %srcinfo = ();
  foreach my ($line) (split '\n', $str) {
    $class->srcinfo_parseline($line, \%srcinfo)
  }
}

method srcinfo_parseline :common ($line, $srcinfo_href = {}) {
  my ($key, $val) = ( $line =~ /^([a-z]+) = (.+)\n$/ );
    
  # $srcinfo{$key} = [ $srcinfo{$key}, $val ]
  #   if $srcinfo{$key} && ref $srcinfo{$key} eq '';

  if ($$srcinfo_href{$key}) {
    $$srcinfo_href{$key} = [ $$srcinfo_href{$key} ]
      if ref $$srcinfo_href{$key} eq '';
    push $$srcinfo_href{$key}->@*, $val
  }
  else {
    $$srcinfo_href{$key} = $val
  }
}

method parse_dep :common ($line) {
  use constant DEP_SO_RE => qr/\.so/;
  use constant VALID_DEPIDEN_RE => qr/${\VALID_PKG_RE_NB}(${\DEP_SO_RE})?/;
  use constant DEP_ATTRSEP_RE => qr/(?:\=)|(?:[\<\>]\=?)|(?:(?:\:))/;  
  use constant DEP_ATTR_RE => qr/^(${\VALID_DEPIDEN_RE})(?:\s*(${\DEP_ATTRSEP_RE})\s*(.+))?\n$/;
  
  my ($depname, $soext, $sep, $attr) = $line =~ DEP_ATTR_RE;

  # use Data::Dumper;
  # say Dumper($line, $depname, $soext, $sep, $attr);

  my %dep_pkgargs = ();

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
  else {
    $dep_pkgargs{name} = $depname
  }

  if ($soext) {
    $dep_pkgargs{file} = $depname
  }

  return \%dep_pkgargs
}