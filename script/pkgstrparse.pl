#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package BS::pkgiden;
use lib 'lib';

class BS::pkgiden : does(BS::Common);

use utf8;
use v5.40;

use Path::Tiny;
use Getopt::Long qw'GetOptionsFromArray :config bundling auto_abbrev';
use List::Util   qw'uniq';
use IPC::Run3;
use Const::Fast;
use BS::Common;
use BS::Package;

field $argv    : param = \@ARGV;
field $cliopts : param(dest) : inheritable = {};
field $env     : param(envstash) =
  {};    #{ map {  } %ENV{ map { uc($_) } qw(debug) } };
field $pkgstub = [];

field $pkgin = [];

ADJUSTPARAMS($params) {
    GetOptionsFromArray(
        $argv, $cliopts,
        'print-fmt|print-format|output-format|fmtstr',
        'delimeter=s',
        'pkgext=s',
        'arch-pattern|arch-regexp=s',
        'list',

        'no-check-file|no-open|ignore-not-found',

        #'group=s',
        'sort=s%',
        '<>' => sub ($barearg) {

            #say STDERR $barearg;
            $self->add_file($barearg);
        }
    );
}

method res {

}

method add_file ( $file, %opts ) {
    try {
        $file =
          path($file)
          ->assert( sub { $$cliopts{"no-check-file"} ? 1 : $_->exists } );

        push @$pkgin, $file
    }
    catch ($e) {
        say STDERR "❌️ Error: Could not open path '$file':\n$e!";
        $file = undef
    }
    $file;
}

method $run (%opts) {
    foreach my $pkg (@$pkgin) {
        $self->parse_pkg_fname($pkg);
    }

    BS::Common::dmsg(
        {
            self       => $self,
            pkgfile_re => $BS::Package::pkgfile_re,

            #'%BS::Package::' => \%BS::Package::
        }
    );

    $self;
}

method run : common ($argv, $dest = undef, %opts) {
    my $self     = $class->new( argv => $argv, dest => $dest, %opts );
    my @pkgstubs = $self->$run(%opts);
    $self;
}

sub info ( $msg, %opts ) {
    say "▶  $msg";
}

sub err ( $msg, %opts ) {
    say STDERR "❌️ Error: $msg";
}

sub fatal ( $msg, %opts ) {
    $msg = err( $msg, %opts, silent => 1 );
    die $msg;
}

method parse_pkg_fname($path) {
    my $basename = $path->basename;
    if ( my (@matches) = ( $basename =~ $BS::Package::pkgfile_re ) ) {
        my %pkgstub =
          map { $_ => shift @matches } qw(name epoch ver rel arch archive);

        push @$pkgstub, \%pkgstub;

        BS::Common::dmsg( { pkgstub => %pkgstub, in => "$path" } );

        return \%pkgstub;
    }

    err("Could not match '$basename' as a package filename!");
    undef;
}

package main;

class main;

use utf8;
use v5.40;

use BS::Common;

sub run {
    my $cliopts = {};
    my $app     = BS::pkgiden->run( \@ARGV, $cliopts );

    # $app->res->outfmt;
    #BS::Common::dmsg( { '%main::' => \%main::, app => $app } );

    #exit( $app->exit // $app->status // $? // 0 );
    exit 0;
}

main->run

