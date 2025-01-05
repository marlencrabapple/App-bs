use Object::Pad;

package BS::Common;
role BS::Common;

use utf8;
use v5.40;

use Carp;

sub bsx ($cmd_aref, %args) {
  %args = (in => undef, out => '', err => '') unless scalar keys %args;

  my $ret = run3($cmd_aref, \$args{in}, \$args{out}, \$args{err});
  
  my $res = BsxResult( cmd => $cmd_aref,
                       %args{qw(in out err)},
                       ret => $ret );

  if ($args{err} || $ret != 0) {
      $args{on_err} && ref $args{on_err} eq 'CODE'
        ? $args{on_err}->($ret, $args{err}, $args{out})
        : croak " > $ret: $args{err}", $res
  }

  $res
}
