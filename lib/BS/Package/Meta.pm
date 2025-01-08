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
