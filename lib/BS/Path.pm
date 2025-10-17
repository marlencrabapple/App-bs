use Object::Pad ':experimental(:all)';

package BS::Path;

class BS::Path :isa(Path::Tiny);

use utf8;
use v5.40;

use Path::Tiny '';

method path :common ($path, %opts) {
  $path = Path::Tiny::path($path)
}
