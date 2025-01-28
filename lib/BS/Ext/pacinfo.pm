use Object::Pad;

package BS::Ext::pacinfo;
role BS::Ext::pacinfo :does(BS::Package::Meta);

use utf8;
use v5.40;

use Carp;
use Data::Printer;
use Data::Dumper;

use constant VALID_KEYS => qw(Name Base Repository);
use constant VALID_KEY_RE => map { qr/^($_)$/i } join '|', (VALID_KEYS);
use constant DEPKEY_RE => qr/^(Requires|Optional Deps)$/i;

method info :common ($pkgstr, %args) {
  my (@out, $in, $err);
  my $res = BS::Common->bsx([ 'pacinfo', $pkgstr ]
                            , out => \@out, in => undef, err => \$err);
  
  die "$err" if $err;
  die "$?: $!" if $res->cmdexit->[0] != 0;

  my %info = ();

  $class->to_href(\@out, %args, dest => \%info);

  carp np @out if $ENV{DEBUG}
}

method pkgbase :common ($pkgstr, %args) {
  my $info = $class->info($pkgstr, %args);
  carp np $info if $ENV{DEBUG};
  ref $$info{base} eq 'ARRAY' ? $info->{base}[0] : $$info{base}
}

method to_href :common ($in, %args) {
  my $res = BS::Common->open_as_href($in, %args
    , parse_line => sub ($line, %args) {
      $class->parse_line($line, %args)
    });

  $res
}

method parse_line :common ($line, %args) {
  my ($key, $value) = map {
    $_ =~ s/${\BS::Common::TRIM_RE}/$1/; $_
  } (split /:/, $line, 1);

  $key = lc($key);
  
  $value = BS::Package::Meta->parse_dep($value, %args)
    if ($args{resolve_deps} // 1) && $key =~ DEPKEY_RE;

  return undef unless $key && $value;
  
  my %debug = (key => $key, val => $value);
  #carp np %debug;

  $key, $value
}