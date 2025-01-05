use Object::Pad;

package BS::Package;
class BS::Package :does(BS::Common);

#inherit App::BS::Package::Meta '$pkgbase';
#:does(App::BS::Package::Meta)

use utf8;
use v5.40;

use Carp;
use IPC::Run3;
use File::chdir;
use Struct::Dumb;
use Syntax::Keyword::Try;
use Syntax::Keyword::Defer;
use Syntax::Keyword::Dynamically;
use List::Util qw(all);
use Path::Tiny;

use constant REPO_BASEURI
  => "https://gitlab.archlinux.org/archlinux/packaging/packages/%s.git";

use constant VALID_PKG_RE_CCLASS_START => "a-z0-9@_\+";
use constant VALID_PKG_RE_NB => qr/[${\VALID_PKG_RE_CCLASS_START}]{1}[${\VALID_PKG_RE_CCLASS_START}\.\-]+/;

field $repo;

field $file_searchstr :param(owns_file) = undef;
field $pkg_idenstr :param(search);

field $dir :param = path($CWD);

field $pkgbuild_file = $dir->children('PKGBUILD')
  || croak "'$dir' does not contain a PKGBUILD file!";

field $srcinfo_file = $dir->children('.SRCINFO')
  || __CLASS__->write_srcinfo(path("$dir/.SRCINFO"));

field $pkgbuilder :param;

ADJUST {
  $dir = path($dir) unless ref $dir && ref $dir eq 'Path::Tiny';
  
  croak "'$dir' is not a directory!" if !-d $dir && $self->env->{offline};

  $repo = sprintf REPO_BASEURI, $self->pkgbase // $self->pkgstr;

  croak "'$dir' does not contain a PKGBUILD file! (" . $self->pkgstr . ")"
    unless $pkgbuild_file = $dir->children('PKGBUILD');

  $pkgbuilder //= App::BS::pkgbuild->new(package => $self)
}

method srcinfo_deps :common ($file) {
  foreach my $line (path($file)->lines_utf8) {

  }
}

# method handle_depends (@depends) {
#   #my $builder = App::BS::pkgbuild;
#   my %pkgargs = ( is_depend => 1 );
  
#   foreach my $dep (\@depends) {
#     if ($dep isa 'BS::Package') {

#     }
#     elsif (ref $dep eq 'HASH'
#            && scalar keys %$dep == 2
#            && all { $$dep{$_} } keys %$dep) {
       
#       my $pkgcand = BS::Package->new(%$dep, %pkgargs) # or type of depend
#     }
#     # Figure out other shared object extensions
#     elsif ($dep =~ /.+\.so$/) {
      
#     }
#   }
# }

# method pkgbuild_dir_exec ($coderef, %args) {
#   try {
#     chdir $dir;
#     defer { chdir $pkgbuilder->startdir };
#     $coderef->(%args)
#   }
#   catch ($e) {
#     chdir $pkgbuilder->startdir;
#     croak "Could not enter '$dir' ($pkgbase - $pkgname)\n  > $e"
#   }
#   finally {
#     chdir $pkgbuilder->startdir
#   }

#   $self
# }

method parse_dep_line :common ($line) {
  use constant DEP_SO_RE => qr/\.so$/;
  use constant DEP_ATTRSEP_RE => qr/(\=)|([\<\>]\=?)|(?:(\:)\s*)/;  
  use constant DEP_ATTR_RE => qr/^(${\VALID_PKG_RE_NB})(${\DEP_SO_RE})?(${\DEP_ATTRSEP_RE})?(.+)?$/;
  
  my ($depname, $soext, $sep, $attr) = $line =~ DEP_ATTR_RE;

  my %dep_pkgargs = ();

  if ($sep ne ':') {
    $dep_pkgargs{version} = $attr;
    $dep_pkgargs{file} = $depname if $soext
  }
  elsif ($sep eq ':') {
    $dep_pkgargs{description} = $attr
  }

  return \%dep_pkgargs
}

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

method updchecksums {
  __CLASS__->bsx(['updchecksums'])
}

method writesrcinfo (@makepkg_args) {
  __CLASS__->printsrcinfo($srcinfo_file, @makepkg_args)->out
}

method printsrcinfo :common ($out, @makepkg_args) {
  $class->bsx(['makepkg', '--printsrcinfo', @makepkg_args], out => \$out);
}

method by_name :common ($searchre, %args) {
  $class->bsx([qw(pacsift --name), $searchre, named2cli(\%args), '<&-']);
}

method owns_file :common ($filere, %args) {
  $class->bsx([qw(pacsift --owns-file), $filere, named2cli(\%args), '<&-']); 
}
