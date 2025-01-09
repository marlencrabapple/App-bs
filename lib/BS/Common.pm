use Object::Pad;

package BS::Common;
role BS::Common;

use utf8;
use v5.40;

use Carp;
use IPC::Run3;
use Struct::Dumb qw( -named_constructors );
use Data::Printer;

struct BsxResult => [qw(cmd in out err run3exit cmdexit)];

sub bsx ($class, $cmd_aref, %args) {
  %args = (in => undef, out => '', err => '') unless scalar keys %args;

  my $ret = run3($cmd_aref, map { ref $_ ? $_ : \$_ } @args{qw(in out err)});
  
  my $res = BsxResult( cmd => $cmd_aref,
                       %args{qw(in out err)},
                       run3exit => $ret,
                       cmdexit => [$?, $!] );

  # if ($args{err} || $ret != 0) {
  #     $args{on_err} && ref $args{on_err} eq 'CODE'
  #       ? $args{on_err}->($ret, $args{err}, $args{out})
  #       : croak " > $ret: $args{err}", $res
  # }

  #$ret
  $res
}
