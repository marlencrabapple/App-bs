use Object::Pad;

package BS::Ext::pacman;
role BS::Ext::pacman :does(BS::Common);

use utf8;
use v5.40;

use Carp;
use Data::Printer;

field $sync;

method sync :common (%args) {
  $args{package} //= 1;
  $args{file} //= 1;
  
  my $now = time;
  state $sync = $now;

  $args{res} //= {};
  $args{dest} //= [];
  $args{now} //= time;

  my (@query_opts, %res);

  if ($args{sync} || ($args{last_sync} && $args{now} == $args{last_sync})) {
    push @query_opts, qw(-y -y)
  }
}

method file_query :common ($filestr, %args) {
  my $now = time;
  state $sync = $now;
  $class->query($filestr, query_opts => ['-Fq'], now => $now
    , %args, last_sync => $sync)
}

method pkg_query :common ($pkgstr, %args) {
  my $now = time;
  state $sync = $now;
  $class->query($pkgstr, query_opts => ['-Sqs'], now => $now
    , %args, last_sync => $sync)
}

method query :common ($str, %args) {
  $args{dest} //= [];
  $args{now} //= time;

  carp np $str, %args if $ENV{DEBUG};

  if ($args{sync} || ($args{last_sync} && $args{now} == $args{last_sync})) {
    push $args{query_opts}->@*, qw(-y -y)
  }

  my $res = BS::Common->bsx([ qw(sudo pacman), $args{query_opts}->@*, $str ]
                            , %args, in => undef, out => $args{dest});

  $res{package} = BS::Common->bsx([ qw(sudo pacman -Su), @query_opts ], %args)
    if $args{package};
  
  $res{file} = BS::Common->bsx([ qw(sudo pacman -F), @query_opts ], %args)
    if $args{file};

  %res->(qw(package file))

  $res
}
