use Object::Pad;

package BS::Ext::pacsift;
role BS::Ext::pacsift :does(BS::Package::Meta);

use utf8;
use v5.40;

use Data::Printer;

method by_name :common ($searchre, %args) {
  $class->sift($searchre, '--name', %args)
}

method owns_file :common ($filere, %args) {
  $class->sift($filere, '--owns-file', %args)
}

method sift :common ($ptn, $cmd, %args) {
  my @out = ();
  my $res = BS::Common->bsx([qw(pacsift), $cmd, $ptn
                            , BS::Common->named2cli(\%args), '<&-']
                          , in => undef, out => \@out);
}
