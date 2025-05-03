use Object::Pad ':experimental(:all)';

package BS::Ext::Common 0.01;
role BS::Ext::Common : does(BS::Common);

use utf8;
use v5.40;

use Const::Fast;
use Syntax::Keyword::MultiSub;

method parse_line : common {
    ...;
}

method filter_output : common {
    ...;
}

#multi sub is_locked ($pacman_dir = "") {
#  BS::Ext::pacman->sync
#}
