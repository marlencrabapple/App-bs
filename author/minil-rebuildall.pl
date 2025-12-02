#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';
use Object::Pad::FieldAttr::Trigger;

use utf8;
use v5.40;

use BS::Common;
use IPC::Run3;
use Getopt::Long qw( GetOptions );

our $install           = 0;
our $trial             = 0;
our $git               = undef;
our $update            = 1;
our $preserve_locallib = 1;
our $outh              = [];
our $errh              = [];

my class Console : does(BS::Common) {
    use IPC::Run3;
    use Stream::Buffered;

    field $inh;
    field $outh;
    field $errh;

    ADJUST : params (:$in, :$out) {
        for ( $in, $out ) {

        }
    }    #$_ = IO::Handle->new() for $out, $err;
};

sub update() {
    unlink "./local" if -d "./local" && !$preserve_locallib;

    foreach my $cmd (qw(install update)) {
        my ( $status, $out, $err, $internalerr ) = cmd( [ 'carmel', $cmd ] );
        if ($status) {
            err("$err ($status)");
            last;
        }
    }
    return 1;
}

sub git_pull_remote ($argstr) {
    my @pairstr = split /:/, $argstr;
    my %opt     = map { split /=/ } @pairstr;
    my @cmd     = ( qw(git pull), (%opt)[qw*branch remote*] );

    BS::Common::dmsg(
        { cmd => \@cmd, opt => \%opt, argstr => $argstr, pairstr => \@pairstr }
    );

    push @cmd, '--rebase' if $opt{rebase};

    cmd( \@cmd, undef );
}

sub cmd ( $cmdlist, $in = \undef, $out = $outh, $err = $errh ) {
    my $run3err = run3( $cmdlist, $in, $out, $err );
    $?, $out, $err, $run3err;
}

sub minil (@cmd) {
    foreach my $cmd (@cmd) {
        cmd( [ qw(carmel exec minil), $cmd ] );
    }
}

sub run {
    GetOptions( 'install', 'trial', 'update-dependencies', 'git-pull=s' );
    update()              if $update;
    git_pull_remote($git) if $git;

    my @minilcmd = qw(clean build dist);
    push @minilcmd, 'install' if $install;
    minil( \@minilcmd );
}

run();
