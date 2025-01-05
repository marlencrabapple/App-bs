use Object::Pad;

package App::BS::CLI::Util;
role App::BS::CLI::Util :does(App::BS::Common);

use utf8;
use v5.40;

method key_cli2env :common ($keys, $sep = qr/-/, $rep = '') {
  map { my $key = $_ =~ s/$sep/$rep/r; uc $key } @$keys
}

method cli2named :common ($cli, $sep = qr/-/, $rep = '_') {
  map { ($_ =~ s/$sep/$rep/r )[0] => $$cli{$_} } keys %$cli
} 

method named2cli :common ($config, $sep = qr/-/, $rep = '_') {
  map {  $_ =~ s/$sep/$rep/r } grep { $$config{$_} != 1 } keys %$config
}
