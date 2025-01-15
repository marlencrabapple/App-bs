use Object::Pad;

package BS::Package;
class BS::Package :does(BS::Package::Meta);

use utf8;
use v5.40;

method updchecksums :common {
  $class->bsx(['updchecksums'])
}

method writesrcinfo :common ($out, @makepkg_args) {
  $class->printsrcinfo($out, @makepkg_args)->out
}

method printsrcinfo :common ($out, @makepkg_args) {
  $class->bsx(['makepkg', '--printsrcinfo', @makepkg_args]
              , out => (ref $out eq 'ARRAY' ? $out : \$out));
}
