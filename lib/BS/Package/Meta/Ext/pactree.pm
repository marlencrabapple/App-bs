use Object::Pad;

package BS::Package::Meta::Ext::pactree;
role BS::Package::Meta::Ext::pactree :does(BS::Package::Meta);

method list_deps :common ($pkgstr, %args) {
  say join ($args{sep} // ' '), $class->pactree($pkgstr)
}

method pactree :common ($pkgstr) {
  my (@out, $in, $err);
  my $status = $class->bsx(['pactree', '-sul', '-o', '-1', $pkgstr]
                          , \@out, undef, \$err);
  
  die "$err" if $err;
  die "$?: $!" if $status != 0;

  my @deps = ();

  foreach my $line (@out) {
    push @deps, $class->parse_dep_line($line);
  }

  \@deps
}