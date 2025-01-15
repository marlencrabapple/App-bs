use Object::Pad;

package BS::Ext::pacinfo;
role BS::Ext::pacinfo :does(BS::Package::Meta);

use utf8;
use v5.40;

use Carp;
use Data::Dumper;

use constant VALID_KEYS => qw(Name Base Repository);
use constant VALID_KEY_RE => map { qr/^($_)$/ } join '|', (VALID_KEYS);
use constant DEPKEY_RE => qr/^(Requires|Optional Deps)$/;

method info :common ($pkgstr, %args) {
  my (@out, $in, $err);
  my $res = BS::Common->bsx([ 'pacinfo', $pkgstr ]
                            , out => \@out, in => undef, err => \$err);
  
  die "$err" if $err;
  die "$?: $!" if $res->cmdexit->[0] != 0;

  my %info = ();

  $class->to_href(\@out, %args, dest => \%info)
}

method pkgbase :common ($pkgstr, %args) {
  my $info = $class->info($pkgstr, %args);
  ref $$info{base} eq 'ARRAY' ? $info->{base}[0] : $$info{base}
}

method to_href :common ($in, %args) {
  carp Dumper($in, %args) if $ENV{DEBUG};
  BS::Common->open_as_href($in, %args
    , parse_line => sub ($line, %args) {
      __PACKAGE__->line($line, %args)
    })
}

method line :common ($line, %args) {
  my ($key, $value) = map {
    $_ =~ s/${\BS::Common::TRIM_RE}/$1/; $_
  } (split /:/, $line);
  
  $key = lc($key);

  say Dumper($line, $key, $value) if $ENV{DEBUG};
  
  $value = BS::Package::Meta->parse_dep($value)
    if $key =~ DEPKEY_RE;

  return undef unless $key && $value;

  lc($key), $value
}