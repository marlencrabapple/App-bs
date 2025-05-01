use Object::Pad ':experimental(:all)';

package BS::Ext::Common 0.01;
role BS::Ext::Common : does(BS::Common) : does(BS::Ext::pacman);

use utf8;
use v5.40;

use Syntax::Keyword::MultiSub;

method is_locked {
    BS::Ext::pacman->sync->status;
}

#multi sub is_locked ($pacman_dir = "") {
#  BS::Ext::pacman->sync
#}
