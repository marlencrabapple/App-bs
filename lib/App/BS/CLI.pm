use Object::Pad;

package App::BS::CLI;
class App::BS::CLI :abstract :does(App::BS::Common)
                             :does(App::BS::CLI::Util);

use utf8;
use v5.40;

use Getopt::Long;

use Inline C => config =>
  enable => autowrap =>
  myextlib => '/usr/lib/libalpm.so.15' =>
  libs => '-lalpm';
