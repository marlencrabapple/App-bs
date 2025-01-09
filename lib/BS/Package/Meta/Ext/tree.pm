use Object::Pad;

use utf8;
use v5.40;


package BS::Package::Meta::Ext::tree;
role BS::Package::Meta::Ext::tree :does(BS::Package::Meta);


use Data::Printer;

method list_deps :common ($pkgstr, %args) {
  our @deps = $class->pactree($pkgstr)->@*;
  #p(@deps);
  my $depstr = join $args{sep} // ' ', @deps;
  $depstr
}

method pactree :common ($pkgstr, %args) {
  my (@out, $in, $err);
  $args{'optdep-depth'} //= 1;
  my $res = BS::Common->bsx( [ 'pactree', '-sul', "-o$args{'optdep-depth'}"
                                            , $pkgstr ]
                              , out => \@out, in => undef, err => \$err );
  
  die "$err" if $err;
  die "$?: $!" if $res->cmdexit->[0] != 0;

  my @deps = ();

  foreach my $line (@out) {
    my $depargs = BS::Package::Meta->parse_dep($line);
    push @deps, $$depargs{name}
  }

  \@deps
}