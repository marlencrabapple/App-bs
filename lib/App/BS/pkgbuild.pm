use Object::Pad;

package App::BS::pkgbuild;
class App::BS::pkgbuild :does(BS::pkgbuild)
                        :does(App::BS::Common)
                        :does(App::BS::CLI::Util);

use utf8;
use v5.40;

use Cwd;
use Carp;
use IPC::Run3;
use File::chdir;
use Future::AsyncAwait;
use Syntax::Keyword::MultiSub;
use List::AllUtils qw(none any all first);
use Syntax::Keyword::Dynamically;
use Path::Tiny;

use Getopt::Long qw(GetOptionsFromArray);
Getopt::Long::Configure("Bundling");

#use BS::Package;

use constant CLI_OPTION_KEYS => qw(pacman-conf makepkg-conf debug verbose);

state %instances;

field $env;
field $argv :param = \@ARGV;
field $opts :param;
field $package :param;
field $pkgbuild_file = $package->pkgbuild_file;
field $pkgbuild_dir = $package->dir;
field $srcinfo_file = $package->srcinfo_file;
field $startdir;
field $stay_fresh;

field $cargs = [qw(C u n c)];
field $margs = [qw(L s i f C c A)];

ADJUST {
  $startdir //= path($CWD);
  $env = $self->env;
  
  my $ret = GetOptionsFromArray(
    $argv, $opts,
    'config=s',
    'makepkg-conf=s', 'pacman-conf=s',
    'debug=s', 'verbose=s',
    'aur-build-args|bs-args=s@',
    'bs-cmds=s@',
    '<>' => sub { $self->handle_pkglist(@_) }
  );

  # $package //= ref $package eq 'App::BS::Package'
  #   ? $package
  #   : App::BS::Package->new( search => $package,
	#                            dir => $path,
	# 		                       pkgbuilder => $self );

  $instances{"$self"} = $self
}

method handle_pkglist ($pkgiden) {
  if (my ($pkg) = BS::Package->new($pkgiden)) {
    $self->buildpkg($pkg)
  }
  else {
    croak "'$pkgiden' was not found!"
  }
}

multi method buildpkg ($package     = $self->package
                     , $build_dirty = !$stay_fresh) {
  state $fresh = 1;
  state $firstrun = 1;

  my $clean_chroot;
  my $makepkg_cleanall;

  if (none { $_ } ($fresh, $firstrun, ($build_dirty // 0))) {
    dynamically $cargs = $cargs->[0..2];
    dynamically $margs = $margs->[0..4];
    $clean_chroot = ',' . shift @$cargs;
    $makepkg_cleanall = join ',', (shift @$margs, shift @$margs)
  }

  state @bs_cmds = qw(aur build);
  state @bs_args = ('--cargs', "C,u,n$clean_chroot",
                    '--margs', "L,A,s,f,i$makepkg_cleanall",
	                  '--makepkg_args', $$env{makepkg_conf},
                    '--pacman-conf', $$env{pacman_conf},
                    qw(--syncdeps --pkgver -d),
                    first { $_ } $env->@[qw(repo reponame)],
                    '--root', $$env{repo_path}, qw(-c -D), $$env{chroot});

  my @bs_out;
  __CLASS__->bsx(\@bs_cmds, out => \@bs_out);

  while (my $line = shift @bs_out) { say $line }

  $fresh = $firstrun = $stay_fresh // 0;
  $self
}

method buildpkgs :common ($packages, %args) {
  foreach my $pkg (@$packages) {
    $class->buildpkg($pkg, %args)
  }
}

method build_self (%args) {
  if ($args{update_repo}) {
    __CLASS__->vcs_git_update_all
  }

  if ($args{printsrcinfo}) {
    $package->writesrcinfo
  }

  if($args{updpkgsums}) {
    $package->updpkgsums;
    $package->writesrcinfo
  }

  $self->buildpkg
}

multi method build_pkg :common ($pkgiden, %args) {
  my $builder = $class->new( package => $pkgiden, %args );

  $builder->package->pkgbuild_dir_exec(sub (%args) { 
    $builder->build_self(delete $args{$pkgiden} // undef)
  }, %args);

  $builder
}

use constant DEFAULT_BRANCHES => qw(main master);
use constant DEFAULT_REFS => (origin => \DEFAULT_BRANCHES,
	                            aur => \DEFAULT_BRANCHES);

method vcs_git_update_all :common (%remote_refs) {
  vcs_git_update_refs(%remote_refs // DEFAULT_REFS)
}

method vcs_git_update_refs :common (%remote_refs) {
  foreach my ($remote => $branches) (%remote_refs) {
    foreach my $branch (@$branches) {
      $class->bmx([qw(git pull), $remote, $branch, '--rebase'])
    }
  }
}