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
use Getopt::Long 'GetOptionsFromArray';

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

#use utf8; use v5.40; say join "\n", grep { $_ =~ /ENV{SELECT}/ } uniq @ARG

#env FILTER=lib32 SELECT='bin\b' perl -e 'use utf8; use v5.40; use List::Util qw(uniq none); say join "\n", grep { (($ENV{SELECT} && $_ =~ /$ENV{SELECT}/) || ($ENV{FILTER} && $_ !~ /$ENV{FILTER}/) || none { $_ } @ENV{ qw(SELECT FILTER) } ) } uniq @ARGV ' $(expac -Q '%F' aarch64-linux-gnu-binutils aarch64-linux-gnu-gdb aarch64-linux-gnu-linux-api-headers aarch64-linux-gnu-gcc aarch64-linux-gnu-glibc )

method pkgfiles (@pkgs) {
  ...
}

method err ($line) {
    chomp $line;
    push @$err, $line;
    warn $line
}

method rebuild_order (@pkgstub) {
	# my @pkgname = (); 
	
	# foreach my $stub (@pkgstub) {
	# 	if (!$$stub{name}) {
	# 		BS::Ext::expac->search($$stub{base})
	# 	}
	# }

	my $res = BS::Ext::expac->search(
		[ grep { $_ } map { @$_{qw(name base)} } @pkgstub ]
		, fields => [ 'base name' ]);

	my @pkgnames = $res->out->@*
}

method base (@pkgstub) {

}

method name (@pkgstub) {
	#foreach
	
}

method run ($argv = \@ARGV) {
  GetOptionsFromArray($argv, $cliopts
		, 'sync'
		, 'optional'
		, 'pkgfield|pkgid|field=s'
		, 'base'
		, 'filter=s'
		, '<>', sub ($barearg) {
			  my $pkgstub = $self->parse_pkgstr($barearg);
				push @$queue, values %$pkgstub
			}
		);

  if ($$cliopts{base}) {
		if ($$cliopts{pkgfield}) {
			

		}
  }

  #my $expac_op = $$cliopts{sync} ? '-Ss' : '-Qs';
	my $expac_op = $$cliopts{sync} ? '-S' : '-Q';

	my $expac_fmt = "$PKGFIELD{$$cliopts{pkgfield}} %D %o";

  foreach my $arg (@$queue) {
		my (@out);#, @err);

		my $run3err = run3([qw(expac)
				  , $expac_op
					, $expac_fmt, $arg]
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
								, sub ($line) { $self->err($line) } )
							}
						}, sub ($line) { $self->err($line) } );
  }

	my $run3err = run3([
		  qw(arch-rebuild-order --no-reverse-depends --repos)
	      ,'universe,extra,core'
		    , ( uniq @$deps) 
		]
		, \undef
		, sub ($line) {
			  chomp $line;
			  say $line
		  }
		, sub ($line) { $self->err($line) });

  #warn join "\n", @$err if scalar @$err;
	BS::Common::dmsg( { err => $err } );
}

package main;
our $pkgiden = pkdiden->new;
$pkgiden->run(\@ARGV)
