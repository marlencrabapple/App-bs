use Object::Pad;

package BS::Package::Meta::Ext::pacinfo;
role BS::Package::Meta::Ext::pacinfo :does(BS::Package::Meta);

use utf8;
use v5.40;

use constant VALID_KEYS => qw(Name Base Repository);

use constant VALID_KEY_RE => map { qr/$_/ } join '|', (VALID_KEYS);

method pacinfo :common ($pkgstr, %args) {
  
}