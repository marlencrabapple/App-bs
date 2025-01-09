use Object::Pad;

package BS::Package::Meta::Ext::sift;
role BS::Package::Meta::Ext::sift :does(BS::Package::Meta);

use utf8;
use v5.40;

use Data::Printer;

# use constant VALID_KEYS => qw(Name Base Repository);

# use constant VALID_KEY_RE => map { qr/$_/ } join '|', (VALID_KEYS);

# method pacinfo :common ($pkgstr, %args) {
#   my (@out, $in, $err);
#   my $res = BS::Common->bsx(['pacinfo', '--verbose', $pkgstr]
#                           , out => \@out, in => undef, err => \$err);
  
#   die "$err" if $err;
#   die "$?: $!" if $res->cmdexit->[0] != 0;

#   my @deps = ();

#   foreach my $line (@out) {
#     my $depargs = BS::Package::Meta->parse_dep($line);
#     push @deps, $$depargs{name}
#   }

#   \@deps 
# }

# method pacinfo_parseline :common ($line, $out) {
#   my ($key, $value) = map { chomp $_ } (split ':', $line);
  
#   $value = BS::Pakage::Meta::parse_dep($value)
#     if $key =~ /^Requires|Optional Deps$/
# }

method by_name :common ($searchre, %args) {
  $class->sift($searchre, '--name', %args)
}

method owns_file :common ($filere, %args) {
  $class->sift($filere, '--owns-file', %args)
}

method sift :common ($ptn, $cmd, %args) {
  my @out = ();
  #$ptn = "^$ptn\$" if $ptn !~ /^\^.+\$$/ || ref $ptn ne 'Regexp';
  my $res = BS::Common->bsx([qw(pacsift), $cmd, $ptn, BS::Common->named2cli(\%args)], out => \@out);
  use Data::Dumper;
  say Dumper($res, $ptn, \@out);
  
}
