#!/usr/bin/env perl

packaeg pc2flags;

use v5.40;

use Getopt::Long;
use Const::Fast;

const our %optenv = ( libs => 'LDFLAGS', cflags => 'CFLAGS' );

our $quiet;
our $verbose = 1;
our $export;
our $findpc;
our @searchdir;
our $static = 1;

sub printenv ($self, $pcfile, $libname, $pkgconfigpath) {
	my @pkgconfigpath = split /:/, $ENV{PKG_CONFIG_PATH};
	my %buildflags = ();
	push @pkgconfigpath, $pkgconfigpath;
	$ENV{PKG_CONFIG_PATH} = $pkgconfigpath = join ':', @pkgconfigpath;

	foreach my $opt (qw(libs cflags)) {
	  $buildflags{$optenv{$opt}} = map { chomp $_; $_ } 
	     `pkg-config --$opt --static "$libname"`;

          say qq!$optenv{$opt}="$buildflags{$optenv{$opt}}!
	}
}

sub run ($class, $argv = \@ARGV) {
    my $self = $class->new;

    GetOptionsFromArray($argv
	   , 'verbose+'
	   , 'quiet'
	   , 'export'
	   , 'findpc'
	   , 'searchdir=s{1,}'
	   , 'static!'
	   , '<>' => sub ($barearg) {
		  my $pcfile = path($barearg);
		  my $libname = ($path->basename =~ s/\.pc$//r);
		  my $pkgconfigpath =  $path->parent;
		  
		  $self->printenv($pcfile, $libname, $pkgconfigpath)
	      };
}

package main;

use v5.40;

pc2flags->run(\@ARGV);
