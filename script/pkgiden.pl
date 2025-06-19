#!/usr/bin/perl
use Object::Pad ':experimental(:all)';

package pkgiden;
class pkdiden :does(BS::Common);

use BS::Common;
use BS::Ext::pacman;
use BS::Ext::expac;
use BS::Ext::pacsift;

use utf8;
use v5.40;

use Const::Fast;
use IPC::Run3;
use List::Util 'uniq';
use Getopt::Long;

field $err = [];
field $deps = [];
field $queue= [];

field $cliopts = {
  pkgfield => 'base',
	filter => $ENV{FILTER}
};

field $rawdeps = [];

const our %PKGFIELD => (
  base => '%e',
  name => '%n'
);

method parse_pkgstr ( $pkgstr, %opts ) {

	# Should be possible to detect if file, regardless of file ext both before 
	# and after parsing as pkgspec
	const my $pkgstr_name_ptn => qr'[a-zA-Z0-9\@_\+]{1}[a-zA-Z0-9\@_\+\.\-]+';

	const my $pkgstr_name_re => qr/
			^(lib\:)?
			( $pkgstr_name_ptn(\.so(?:\.[0-9\]+)?)
			  | $pkgstr_name_ptn )
		/x;

	const my $pkgver_forbidden => quotemeta(':/-') . '\s';

	const my $pkgver_re => qr'
		(\=|[\<\>](?:\=)?)
		([^$pkgver_forbidden]+)
	'x;

	const my $optdep_re => qr/(:(:)\s+(.+))/;

	const my $pkgstr_re => qr/
			$pkgstr_name_re #
			(?:$pkgver_re)?
			$optdep_re
		/x;


	my ( $prefix, $_pkgstr, $isfile, $sep, $attr, @extra ) =
		$pkgstr =~ $pkgstr_re;

	my %pkgstub = ();

	$pkgstub{name} = $_pkgstr;

	if ($sep) {
			if ( $sep ne ':' ) {
					$pkgstub{version} = $attr;
					$pkgstub{cmp_op}  = $sep;
			}
			elsif ( $sep eq ':' ) {    # Optional dependency most likely
																	# Will have parsed that out elsewhere
					$pkgstub{description} = $attr;
					$pkgstub{name}        = $_pkgstr;
			}
	}

	if ( $isfile || $opts{database} && $opts{database} eq 'file' ) {
			$pkgstub{file} //= $_pkgstr;

			#my $res = BS::Ext::pacman->pacman_query( $_pkgstr, database => 'file' );
			my $res = BS::Ext::pacsift->owns_file($_pkgstr, %opts);

			#BS::Common::dmsg { res => $res };

			$pkgstub{repo} = $$res{repo}    if $$res{repo};
			$pkgstub{name} = $$res{pkgname} if $$res{pkgname};
	}

	BS::Common::dmsg(
			{
					_pkgstr => $_pkgstr,
					isfile  => $isfile,
					sep     => $sep,
					attr    => $attr,
					pkgstub => \%pkgstub
			}
	);

	\%pkgstub;
}

method err ($line) {
    chomp $line;
    push @$err, $line;
    warn $line
}

method run ($argv = \@ARGV) {
  GetOptionsFromArray($argv, $cliopts
		, 'sync'
		, 'optional'
		, 'pkgfield|pkgid|field=s'
		, 'base'
		, 'filter=s'
		, '<>', sub ($barearg) {
				push @$queue, $barearg
			}
		);

  if ($$cliopts{base}) {
		if ($$cliopts{pkgfield}) {

		}
  }

  #my $expac_op = $$cliopts{sync} ? '-Ss' : '-Qs';
	my $expac_op = $$cliopts{sync} ? '-S' : '-Q';

  foreach my $arg (@$queue) {
		my (@out);#, @err);

		my $run3err = run3([qw(expac)
				  , $expac_op
					, "$PKGFIELD{$$cliopts{pkgfield}} %D", $arg]
					, \undef
					, sub ($line) {
							chomp $line;

							foreach my $dep (split ' ', $line) {
								run3([ qw(expac)
								  #, ($expac_op =~ s/^([SQ]{1})s$/$1/r)
									, $expac_op
								  , $PKGFIELD{$$cliopts{pkgfield}}
								  , $dep
								]
								, \undef
								, sub ($line) {
													chomp $line;
													push @$deps, $line
												}
										, \&err)
							}
						}, \&err);
  }

	my $run3err = run3([
		  qw(arch-rebuild-order --no-reverse-deps --repos)
	      ,'universe,extra,core'
		    , (grep { $ENV{FILTER} ? $_ !~ /^$ENV{FILTER}/ : 1 } uniq @$deps) 
		]
		, \undef
		, sub ($line) {
			chomp $line;
			say $line
		}, \&err);

  warn join "\n\n", @$err if scalar @$err;
	BS::Common::dmsg( { err => $err } );
}
