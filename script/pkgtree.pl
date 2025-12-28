#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package pkgtree;

class pkgtree;

use utf8;
use v5.40;

use Getopt::Long
  qw(GetOptionsFromArray :config no_ignore_case auto_abbrev long_prefix_pattern=--?);
use Const::Fast;
use List::Util qw'first uniq';
use IPC::Run3;

use BS::Package;

const our %fieldmap => (
    base    => '%e',
    name    => '%n',
    depends => '%d',
    files   => '%F'
);    #, repo => '');

const our @sort_allow => qw( buildorder );

field $argv : param //= \@ARGV;

field @in;

field $buildorder = 1;
field $sort       = qw'buildorder';

field $asc;
field $desc;
field $reverse;

field $uniq = 1;

field $base = 1;
field $name;
field @field = qw(base);

field $fmtstr = '%e';

# Default is hybrid: will do expac -Ss if pkgstr has regex meta-characters
field $exact = 0;
field $regex = 1;

field $sep = ' ';

field %pkgtree = ();

ADJUST {
    GetOptionsFromArray(
        $argv, 'base', 'name', 'uniq!',
        'field=s{1,}',
        'fmtstr=s',
        'buildorder!',
        'sort=s{1,}',
        'asc', 'desc', 'exact!', 'debug',
        '<>' => sub ($barearg) {
            push @in, $barearg;
        }
    )
}

method run3out ( $line, %opt ) {
    chomp $line;
    push $opt{dest}->@*, $line if $opt{dest} && ref $opt{dest} eq 'ARRAY';
    BS::Common::info($line);
}

method pkgfield ( $pkglist, $field, %opt ) {
    my $op = '-S';
    $op .= 's' unless $opt{exact};

    $pkglist = [$pkglist] unless ref $pkglist eq 'ARRAY';

    my @cmd = ( 'expac', $op, $fieldmap{$field} );

    $opt{dest} = [] unless $opt{dest} && $opt{dest} isa 'ARRAY';

    my $outh = sub ($line) { $self->run3out( $line, %opt{dest} ) };

    if ( $opt{exact} ) {
        run3( [ @cmd, @$pkglist ], \undef, $outh );
    }
    else {
        foreach my $pkgstr (@$pkglist) {
            run3( [ @cmd, $pkgstr ], \undef, $outh );
        }
    }

    $opt{dest};
}

method pkgbase ( $pkglist, %opt ) {
    $self->pkgfield( $pkglist, 'base', %opt );
}

method pkgname ( $pkglist, %opt ) {
    $self->pkgfield( $pkglist, 'name', %opt );
}

method pkgtree ( $pkglist, %opt ) {

    my @pkgname;
    $self->pkgname( $pkglist, %opt, dest => \@pkgname );

    # for my $pkgstr ( $pkglist isa 'ARRAY' ? @$pkglist : $pkglist ) {
    #     run3( [ qw(expac -Ss '%n'), $pkgstr ],
    #         \undef,
    #         sub ($line) { $self->run3out( $line, dest => \@pkgname ) } );
    # }

    my @pkgtree;

    foreach my $pkgname (@pkgname) {
        run3( [ qw(pactree -lus), $pkgname ],
            \undef,
            sub ($line) { $self->run3out( $line, dest => \@pkgtree ) } );
    }
}

method $run (%opt) {

    $self->pkgtree( \@in, %opt );
}

method run : common ($argv = \@ARGV, %opt) {
    my $self    = $class->new( argv => $argv, %opt );
    my @pkgtree = $self->$run;

    #say join $sep, @pkgtree;
}

package main;

pkgtree->run( \@ARGV )
