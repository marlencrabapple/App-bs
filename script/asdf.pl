#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package asdf;

class asdf : does(BS::Common)
  : does(BS::Ext::expac);

use utf8;
use v5.42;

use IPC::Run3;
use List::Util 'uniq';
use Const::Fast;
use Data::Dumper;
use Getopt::Long;
use Inline::Module;
use Syntax::Keyword::Dynamically;

use BS::Common;
use BS::Package;
use BS::Ext::pacsift;
use BS::Ext::expac;

const our %FIELD_FMT => (
    base => '%e',
    name => '%n'
);

field $err;
field $deps;
field $queue : accessor;
field $dep_pkgstub;
field $expac_op = '-Q';
field $find;

field $cliopts = { pkgfield => 'base' };

method err ($line) {
    chomp $line;
    push @$err, $line;
    warn $line;
}

method flatten_pkgiden ($pkgiden) {
    map {    # Unpack if pkgstub/hashref
        ref $_ eq 'HASH'
          ? $_->@{qw(name base file lib)}
          : $_
    } ( ref $pkgiden eq 'ARRAY' ? @$pkgiden : $pkgiden );
}

method pkgtree ( $pkgiden, %opts ) {

}

method pkgdepends ( $pkgiden, %opts ) {
    my $expac_fmt;

    if ( !$opts{resfmt} ) {
        $expac_fmt = "%e (%n): %D";

        #$expac_fmt .= " %D" if $opts{depends};
        $expac_fmt .= " %o" if $$cliopts{optional} // $opts{optional};
    }
    else {
        $expac_fmt = $opts{resfmt};
    }

    dynamically $expac_op = $$cliopts{sync} ? '-S' : '-Q';
    dynamically $find     = 's' if $$cliopts{find};

    run3(
        [ 'expac', "$expac_op$find", $expac_fmt, unpack_pkgiden($pkgiden) ],
        undef,
        sub ($line) {
            chomp $line;
            push @$deps, $line;
        },
        \&err
    );
}

method pkg_base_names ($pkgiden) {
    my @base_name = ();
    dynamically $expac_op = $$cliopts{sync} ? '-S' : '-Q';
    dynamically $find     = 's' if $$cliopts{find};

    run3(
        [ 'expac', "$expac_op", "%e %n", @$deps ],
        undef,
        sub ($line) {
            chomp $line;
            my ( $base, @pkgname ) = split ' ', $line;
            push @base_name,
              {
                base => $base,
                name => (
                    scalar @pkgname
                    ? \@pkgname
                    : undef
                )
              };
        },
        \&err
    );

    return @base_name;
}

method run : common ($argv, %runopts) {
    $runopts{queue}       //= [];
    $runopts{cliopt_dest} //= {};
    $runopts{res}         //= [];

    my $self = $class->new(
        argv    => $argv,
        dest    => $runopts{dest},
        getopts => [
            'sync',
            'optional',
            'find|query',
            'rebuild-order',
            'reverse-depends',
            'pkgfield|pkgid|field=s',
            '<>' => sub ($barearg) {
                push $runopts{queue}->@*, $barearg;
            }
        ],
        %runopts
    );

    $self->pkg_base_names( $self->queue );

    dmsg( \%runopts{qw(queue cliopt_dest res)} );

    say join ' ', grep { $ENV{SELECT} ? $ENV{SELECT} =~ /^$ENV{SELECT}$/ : 1 }
      grep { $ENV{FILTER} ? $_ !~ /^$ENV{FILTER}/ : 1 } uniq $self->res->@*;

    $self;
}

package main;

use utf8;
use v5.42;

use Data::Dumper;

my $app = asdf->run( \@ARGV );
warn Dumper( { app => $app } )
