use Object::Pad ':experimental(:all)';

package BS::Package::Meta;
role BS::Package::Meta :does(BS::Common)
                       :does(BS::alpm);

use utf8;
use v5.40;

use Carp;
use List::Util qw(any);
use Data::Printer;
use Struct::Dumb;
use Syntax::Keyword::MultiSub;

#use BS::Package;
use BS::Ext::pacsift;
use BS::Ext::pacinfo;

use constant VALID_PKG_RE_CCLASS_START => "a-zA-Z0-9\@_\+";
use constant VALID_PKG_RE_NB => qr/[${\VALID_PKG_RE_CCLASS_START}]{1}[${\VALID_PKG_RE_CCLASS_START}\.\-]+(\.so)|[${\VALID_PKG_RE_CCLASS_START}]{1}[${\VALID_PKG_RE_CCLASS_START}\.\-]+/;

struct PkgDepends => [qw(make optional check depends)];
struct PkgChecksums => [qw(ck md5 sha1 sha256 sha512 b2)];

field $pkgname :param(name);

#field $name = [ ref $pkgname eq 'ARRAY' ? $pkgname->@* : $pkgname ];
field $name { ref $pkgname eq 'ARRAY' ? $pkgname : [ $pkgname ] };
field $base :param { $pkgname unless defined ref $pkgname };

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

field $srcinfo :param;
field $srcinfo_path;

ADJUSTPARAMS ($params) {
  $self->_srcinfo_unpack_into
}

method _srcinfo_unpack_into {
  if ($srcinfo eq 'HASH') {
    #my $meta = Object::Pad::MOP::Class->for_caller;

    $base = $$srcinfo{pkgbase};
    $name = $$srcinfo{pkgname};

    $depends = PkgDepends();


    #$checksums = PkgChecksums();
    #...
  }
  elsif ($srcinfo) {
    $srcinfo = __CLASS__->parse_srcinfo(__CLASS__->prepare_file($srcinfo));
    $self->_srcinfo_unpack_into
  }
}

method parse_dep :common ($line, %args) {
  use constant PACINFO_SO_PREFIX => qr/(?:lib\:)?/;
  use constant DEP_SO_RE => qr/\.so/;
  use constant VALID_DEPIDEN_RE => qr/${\PACINFO_SO_PREFIX}(${\VALID_PKG_RE_NB})(?:${\DEP_SO_RE})?/;
  use constant DEP_ATTRSEP_RE => qr/(?:\=)|(?:[\<\>]\=?)|(?:(?:\:))|(?:\.)/;  
  use constant DEP_ATTR_RE => qr/^${\VALID_DEPIDEN_RE}(?:\s*(${\DEP_ATTRSEP_RE})\s*(.+))?\n?$/;
  
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
    my $res =  BS::Common->bsx([ qw(sudo pacman)
                               , @fquery_args, $dep_pkgargs{file} ]
                               , in => undef, out => \@out);

    my $match = $res->out->[-1];
    chomp $match;

    ($dep_pkgargs{repo}, $dep_pkgargs{name}) = (split /\//, $match)
  }

  if ($args{resolve_base} // $ENV{RESOLVE_BASE} // 1) {
    try {
      my $info = BS::Ext::pacinfo->info($dep_pkgargs{name}, no_dupes => 1);
      $dep_pkgargs{base} = ref $$info{base} eq 'ARRAY'
        ? $info->{base}[0] : $$info{base}
    }
    catch ($e) {
      my @out;
      my $res = BS::Common->bsx([ qw(sudo pacman -Sqs), $dep_pkgargs{name} ]
                                    , in => undef, out => \@out);

      chomp $out[0];

      try {
        my $info = BS::Ext::pacinfo->info($out[0], no_dupes => 1);
        $dep_pkgargs{base} = ref $$info{base} eq 'ARRAY'
          ? $info->{base}[0] : $$info{base}
      }
      catch ($e) {
        carp np $e
      }
    }

  }
  
  \%dep_pkgargs
}

method from_srcinfo :common ($in, %args) {
  my $href = $class->parse_srcinfo(
    BS::Common->tie_file($in, delete $args{out}), %args);

  BS::Package->new(srcinfo => $href)
}

method parse_srcinfo :common ($in, %args) {
  my ($as_aref, $as_path);
  BS::Common->open_as_href($in, %args, parse_line => sub ($line, %args) {
    __PACKAGE__->parse_srcinfo_line($line, %args)
  })
}

method parse_srcinfo_line :common ($line, %args) {
  # Not sure if this bit is thread-safe, but there shouldn't be any
  # issues with usage in non-blocking event-loop or forking code
  state $_res_buff = $args{dest};
  $_res_buff = $args{dest} if keys $args{dest}->%* && $args{dest} ne $_res_buff;

  use constant SRCINFO_LINE_RE => qr/^([a-z0-9_]+)\s*=\s*(.+)\n?$/i;

  my ($key, $val) = ($line =~  SRCINFO_LINE_RE);
  return undef unless $key && $val;
    
  # $srcinfo{$key} = [ $srcinfo{$key}, $val ]
  #   if $srcinfo{$key} && ref $srcinfo{$key} eq '';

  if ($key =~ /depends/) {
    $val = $class->parse_dep($val, %args)
  }

  # if ($$_res_buff{$key}) {
  #   $$_res_buff{$key} = [ $$_res_buff{$key} ]
  #     if ref $$_res_buff{$key} ne 'ARRAY';
  #   push $$_res_buff{$key}->@*, $val
  # }
  # else {
  #   $$_res_buff{$key} = $val
  # }

  return $key, $val
}
