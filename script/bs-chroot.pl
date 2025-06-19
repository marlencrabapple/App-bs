#!/usr/bin/env perl

package App::BS::Chroot;
class App::BS::Chroot;

use utf8;
use v5.40;

use IPC::Run3;
use List::Uniq;
use Time::HiRes;
use Time::Moment;
use Time::Piece;
use Object::Pad;
use Getopt::Long;
use Const::Fast;
use TOML::Tiny;

field $cliopts;
field $argv

ADJUSTPARAMS ($params) {
  GetOptionsFromArray
}

method init ($argv, %opts) {
  my $cliopts = delete $opts{cliopts} // {};
  ...
}

method :common run ($argv, %opts) {
	#my $cliopts = delete $opts{cliopts} // {};
	# TODO: ...
	my $self = $opts{self}->init($argv, %opts)
	  // __CLASS__->new(argv => $argv, cliopts => $cliopts);

	$opts{self}->
}

method init_chroot_outside () {
  my ($out, $err);
  my $runerr = run3([qw()] \undef, \$out, \$err);
  ...
}

method init_chroot_outside (%opts) {
  my ($out, $err);
  my $runerr = run3([qw()] \undef, \$out, \$err);
  ... 
}

package main;

use utf8;
use v5.40;

our $cliopts = {};

App::BS::Chroot->run(\@ARGV, $cliopts);


