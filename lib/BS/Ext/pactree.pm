use Object::Pad;

package BS::Ext::pactree;
role BS::Ext::pactree :does(BS::Common);

use BS::Package::Meta;

use utf8;
use v5.40;

use Data::Printer;

method list_deps :common ($pkgstr, %args) {
  if ($args{debug}) {
    say "${class}::list_deps('$pkgstr', ...) args:";
    p %args
  }

  use constant DEFORDER_RE => qr/^asc.*/i;

  state $altorder = ($args{default_order} // 'asc') =~ DEFORDER_RE
    ? 'desc' : 'asc';

  state $altorder_re = qr/^($altorder|r).*/i;

  my @deps;

  my @out = $class->tree($pkgstr
    , linear => 1, unique => 1, sync => 1, optional => 1
    , sync => delete $args{sync}, %args)->@*;

  foreach my $line (@out) {
    my $depargs = BS::Package::Meta->parse_dep($line, %args);
    push @deps, $$depargs{name} unless $$depargs{name} eq $pkgstr
  }

  join $args{sep} // ' ', ($args{order} !~ $altorder_re
    ? @deps
    : reverse @deps)
}

method tree :common ($pkgstr, %args) {
  if ($args{debug}) {
    say "${class}::tree('$pkgstr', ...) args:";
    p %args
  }

  my (@flagsargs, @intsargs, @out, $in, $err);
  $args{optional} //= 1;

  foreach my ($key, $value) (%args{qw(sync unique linear)}) {
    push @flagsargs, substr $key, 0, 1 if $value
  }

  foreach my ($key, $value) (%args{qw(depth optional)}) {
    push @intsargs, '-' . substr($key, 0, 1) . $value if $value
  }

  my $res = BS::Common->bsx( [ 'pactree', ('-'. join '', @flagsargs)
                                 , @intsargs, $pkgstr ], %args,
                           , out => \@out, in => undef, err => \$err );
  
  die "$err" if $err;
  die "$?: $!" if $res->cmdexit->[0] != 0;

  \@out
}
