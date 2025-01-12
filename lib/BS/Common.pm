use Object::Pad;

package BS::Common;
role BS::Common;

use utf8;
use v5.40;

use Carp;
use IPC::Run3;
use Struct::Dumb qw( -named_constructors );
use Data::Printer;

use parent 'Exporter';
our @EXPORT = qw(bsx);

struct BsxResult => [qw(cmd in out err run3exit cmdexit)];

method bsx :common ($cmd_aref, %args) {
#sub bsx ($class, $cmd_aref, %args) {
  %args = (in => undef, out => '', err => '') unless scalar keys %args;

  my $ret = run3($cmd_aref, map { ref $_ ? $_ : defined $_ ? \$_ : undef } @args{qw(in out err)});
  
  my $res = BsxResult( cmd => $cmd_aref,
                       %args{qw(in out err)},
                       run3exit => $ret,
                       cmdexit => [$?, $!] );

  if ($args{err} && ${$args{err}} || $ret != 1) {
      $args{on_err} && ref $args{on_err} eq 'CODE'
        ? $args{on_err}->($ret, $args{err}, $args{out})
        : croak " > $ret: ${$args{err}}", $res
  }

  $res
}

method key_cli2env :common ($keys, $sep = qr/-/, $rep = '') {
  map { my $key = $_ =~ s/$sep/$rep/r; uc $key } @$keys
}

method cli2named :common ($cli, $sep = qr/-/, $rep = '_') {
  map { ($_ =~ s/$sep/$rep/r )[0] => $$cli{$_} } keys %$cli
} 

method named2cli :common ($config, $sep = qr/-/, $rep = '_') {
  map {  $_ =~ s/$sep/$rep/r } grep { $$config{$_} != 1 } keys %$config
}
