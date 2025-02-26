use Object::Pad ':experimental(:all)';

package BS::Ext::Common 0.01;
role BS::Ext::Common;

use utf8;
use v5.40;

use BS::Ext::pacman;
use Syntax::Keyword::MultiSub;

APPLY {
  ...
}

ADJUST {
  ...
}

method is_locked {
  BS::Ext::pacman->sync->status
}

#multi sub is_locked ($pacman_dir = "") {
#  BS::Ext::pacman->sync 
#}
