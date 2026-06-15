#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';
use Object::Pad::FieldAttr::Trigger;

use utf8;
use v5.40;

use lib 'lib';

use BS::Common;
use IPC::Nosh;
use IO::Handle::Common;
use Getopt::Long
  qw(GetOptionsFromArray :config no_ignore_case auto_abbrev long_prefix_pattern=--?);

our $clean = 0;
our $build = 1;
our $dist  = 1;
our $install           = 0;
our $trial             = 0;
our $git               = undef;
our $update            = 1;
our $preserve_locallib = 1;
our $outh              = [];
our $errh              = [];

sub update() {
    unlink "./local" if -d "./local" && !$preserve_locallib;

    foreach my $cmd (qw(install update)) {
	info("Running `carmel $cmd`...");

        my $run = run( [ 'carmel', $cmd ] );
        
	if ($run->status) {
            error('carmel exited with o non-zero status code: '. $run->status);

	    say STDERR $_ for map { chomp $_; "  carmel: $_"  } $run->err->lines_utf8;
    last;
        }
    }

    1
}

sub git_pull_remote ($argstr) {
    my @pairstr = split /:/, $argstr;
    my %opt     = map { split /=/ } @pairstr;
    my @cmd     = ( qw(git pull), (%opt)[qw*branch remote*] );

    dmsg( \@cmd, \%opt, $argstr, \@pairstr );

    push @cmd, '--rebase' if $opt{rebase};

    my $cmd = say join ' ', @cmd;
    info "Running `$cmd`...";

    my $run = run( \@cmd );

    if ($run->status) {
	    error 'git exited with a non-zero status code: ' . $run->status;
            say STDERR $_ for map { chomp $_; "  git: $_" } $run->err->lines_utf8;
    }
}

sub minil (@cmd_ahref) {
    foreach my $cmd (@cmd_ahref) {
	info 'Running `carmel exec minil ' 
	 . (join ' ', $$cmd{cmd}, $$cmd{args}->@*) 
	 . '`...';
        
	 my $run = run( [ qw(carmel exec minil), $$cmd{cmd}, $$cmd{args}->@* ] );
    }
}

sub cli {
    GetOptions( 'clean+', 'dist', 'build', 'install',
        'trial', 'updatedeps|update-dependencies',
        'update|git-pull-remote=s' );

    update()              if $update;
    my $run = git_pull_remote($git) if $git;

    my @minilcmd;

    foreach my $cmd (qw(clean build dist install clean>1)) {
        my ( $cmd, $cond ) = $cmd =~ /^([a-z]+)
                                      ([=<>]{1}(?:=)?
                                      ([0-9]+))?$
                                    /x;
        push @minilcmd, { $cmd => [ $trial ? '--trial' : () ] };
    }

    # push @minilcmd, 'clean' if $clean;
    # push @minilcmd, 'build' if $build;
    # push @minilcmd, 'dist'  if $dist;
    # push @minilcmd, 'install' if $install;
    # push @minilcmd, 'clean',  if $clean > 1;
    # push @minilcmd, '--trial' if $trial

    minil( \@minilcmd );
}

cli();
