use Object::Pad;

package App::BS::CLI;
class App::BS::CLI :abstract;

use utf8;
use v5.40;

use Getopt::Long;

  use Inline C => config =>
    enable => autowrap =>
    myextlib => '/usr/lib/libalpm.so.15' =>
    libs => '-lalpm -lalpm_list -lalpm_depends -lalpm_packages';
