#!/usr/bin/env perl

use utf8;
use v5.40;

use Getopt::Long;

my $install = 0;
my $trial = 0;
my $git = undef;
my $update = 1;

GetOptions('install',
           'trial',
           'update-dependencies',
           'git-pull=s');

my @cmd = qw(clean build dist);

push @cmd, 'install' if $install == 1;

if($update) {
    unlink "./local" if -d "./local";
  say `carmel install && carmel update` or die "Dependency error: $! ($?)";
}

if ($git) {
    warn '-git-pull not yet implemented';
    ...
    #`git pull
}

foreach my $cmd (@cmd) {
    say `carmel exec minil $cmd`
}