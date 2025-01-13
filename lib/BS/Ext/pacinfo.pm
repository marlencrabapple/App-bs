use Object::Pad;

package BS::Ext::pacinfo;
role BS::Ext::pacinfo :does(BS::Package::Meta);

use utf8;
use v5.40;

# use constant VALID_KEYS => qw(Name Base Repository);

# use constant VALID_KEY_RE => map { qr/$_/ } join '|', (VALID_KEYS);

method info :common ($pkgstr, %args) {
  my (@out, $in, $err);
  my $res = BS::Common->bsx([ 'pacinfo', '--verbose', $pkgstr ]
                          , out => \@out, in => undef, err => \$err);
  
  die "$err" if $err;
  die "$?: $!" if $res->cmdexit->[0] != 0;

  my %info = {};

  $class->pacinfo_parse(\@out, dest => \%info)

  # my @deps = ();

  # foreach my $line (@out) {
  #   my $depargs = BS::Package::Meta->parse_dep($line);
  #   push @deps, $$depargs{name}
  # }

  #\@deps 
}

method pacinfo_parse :common ($in, %args) {
  BS::Common::open_as_href($in, %args, dest => $args{dest}
    , parse_line => sub ($line, $dest) {
    __PACKAGE__->pacinfo_parseline->($line, $dest)
  })
}

method pacinfo_parseline :common ($line, $out) {
  my ($key, $value) = map { chomp $_ } (split ':', $line);

  say Dumper($key, $value);
  
  $value = BS::Pakage::Meta::parse_dep($value)
    if $key =~ /^Requires|Optional Deps$/;

  $key, $value
}