#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package PKGBUILD::clone;
class PKGBUILD::clone :does(BS::Common);

use utf8;
use v5.42;

use Getopt::Long;
use IPC::Run3;

# Not sure if which repo I rebase on/into changes the order of this or not
#
# Clone packages in ARGV to new working directory
# Check in $BS_ROOT/pkgbuild for folder with equivalent name
#   - maybe check individual .SRCINFO files to allow more leeway with folder
#     names
# 
# Alternate (probably correct order):
# Check for packages in @ARGV in $BS_ROOT/pkgbuild
#   - pkgctl
#   - package installed:
#       - ...
#   - package not installed: 
#   - aur fetch (or use aur's API itself, this may make more sense)
# sdfsafdsffasdf
#
# Depends on #1 if package is installed and the source repo is configured in 
# pacman.conf and #2 mainly that

field $queue;

ADJUSTPARAMS ($params) {
  GetOptionsFromArray($argv,
    'repository=s@'
    '<>' => sub ($barearg) {
      push @$queue, $barearg;
    })
}

method $run (%opts) {

}

method run :common ($obj_or_constructor, %opts) {
  die "First argument must be a HASH/ARRAY ref with a valid '$class'"
    . " constructor." # TODO: List off fields

  if ($obj_or_constructor isa PKGBUILD::clone) {
    $obj_or_constructor->$run(%opts)
  }
  elsif (ref $obj_or_constructor =~ 'ARRAY|HASH') {
    $obj_or_constructor = $class->new($obj_or_constructor)
  }
} 

package main;

use utf8;
use v5.42;

my $pkgbase_clone = PKGBASE->clone->new( argv => \@ARGV );
$pkgbase_clone->run()