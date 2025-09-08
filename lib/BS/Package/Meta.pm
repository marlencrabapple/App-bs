use Object::Pad ':experimental(:all)';

use utf8;
use v5.40;

package BS::Package::Meta;
role BS::Package::Meta : does(BS::Common);

field $base    : inheritable : param : accessor = "";
field $name    : inheritable : param : accessor //= [$base];
field $current : inheritable : accessor //= $$name[0];

field $version   : inheritable : param : accessor = "";
field $rel       : inheritable : param : accessor = "";
field $epoch     : inheritable : param : accessor = "";
field $sources   : inheritable : param : accessor = [];
field $checksums : inheritable : param : accessor = [];
