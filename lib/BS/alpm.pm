use Object::Pad ':experimental(:all)';

package BS::alpm;
role BS::alpm :does(BS::Common);

use utf8;
use v5.40;

#use Inline C => "alpm_initialize();"
use Inline C => Config
    => enable => 'autowrap'
  , myextlib => '/usr/lib/libalpm.so.15'
  , libs => '-lalpm -lalpm_list -lalpm_depends -lalpm_packages';

use Data::Dumper;
use Data::Printer;

APPLY {
	# alpm_initialize();
	#BS::alpm::alpm_initialize();
}

method print_self {
  #say BS::alpm::alpm_initialize();
  #say Dumper($self);
  p $self if $ENV{DEBUG}
}
