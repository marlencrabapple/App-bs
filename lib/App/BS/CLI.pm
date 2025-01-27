use Object::Pad;

package App::BS::CLI;
class App::BS::CLI :abstract :does(App::BS::Common)
                             :does(App::BS::CLI::Util)
                             :does(BS::alpm);


use utf8;
use v5.40;

use Pod::Usage;
use Getopt::Long qw(:config auto_abbrev permute bundling);

ADJUST {
  GetOptions($self->cliopts
    , $self->getopts_setup->@*, "debug+"
    , "version" => sub { VersionMessage() }
    , "help" => sub { HelpMessage() })
}
