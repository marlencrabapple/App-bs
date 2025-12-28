#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package pkgtree;

class pkgtree;

use utf8;
use v5.40;

use lib 'lib';

use Getopt::Long
  qw(GetOptionsFromArray :config no_ignore_case auto_abbrev long_prefix_pattern=--?);
use Const::Fast;
use List::Util qw'first uniq';
use IPC::Run3;

use BS::Common;
use BS::Package;
use BS::Run;

const our @REPO_DEFAULT => qw(
  universe
  core
  extra
);

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

field $reversedeps = 0;
field @repo        = @REPO_DEFAULT;

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
        'repo=s{1,}', 'reversedeps!',
        '<>' => sub ($barearg) {
            push @in, $barearg;
        }
    )
}

method outh ( $dest, %opt ) {
    $dest //= delete $opt{dest};
    sub ($line) { $self->run3out( $line, %opt, dest => $dest ) }
}

method run3out ( $line, %opt ) {
    chomp $line;
    my @line = $opt{split} ? split /$opt{split}/, $line : ($line);
    push $opt{dest}->@*, @line if $opt{dest} && ref $opt{dest} eq 'ARRAY';
    BS::Common::dmsg( \@line );
    @line
}

method pkgfield ( $pkglist, $field, %opt ) {
    my $op = '-S';
    $op .= 's' unless $opt{exact};

    $pkglist = [$pkglist] unless ref $pkglist eq 'ARRAY';

    my @cmd = ( 'expac', $op, $fieldmap{$field} );

    $opt{dest} = [] unless $opt{dest} && ref $opt{dest} eq 'ARRAY';

    my $outh = $self->outh( $opt{dest} );

    if ( $opt{exact} ) {
        run( [ @cmd, @$pkglist ], \undef, $outh );
    }
    else {
        foreach my $pkgstr (@$pkglist) {
            run( [ @cmd, $pkgstr ], \undef, $outh );
        }
    }

    # push @cmd, $opt{exact} ? @$pkglist

    BS::Common::dmsg( $outh, \@cmd, $pkglist, $field, \%opt, $op );

    $opt{dest};
}

method pkgbase ( $pkglist, %opt ) {
    $self->pkgfield( $pkglist, 'base', %opt );
}

method pkgname ( $pkglist, %opt ) {
    $self->pkgfield( $pkglist, 'name', %opt );
}

method pactree ( $pkglist, %opt ) {
    $opt{dest} //= [];
    $pkglist = [$pkglist] unless ref $pkglist eq 'ARRAY';
    foreach my $pkgstr (@$pkglist) {
        run( [ qw(pactree -lus), $pkgstr ], \undef, $self->outh( $opt{dest} ) );
    }
    $opt{dest};
}

method pkgtree ( $pkglist, %opt ) {

    my @pkgname;
    $self->pkgname( $pkglist, %opt, dest => \@pkgname );

    my @pactree;
    $self->pactree( \@pkgname, dest => \@pactree );

    my @archrebuildorder_cmd = ( qw(arch-rebuild-order --repo), @repo, );
    push @archrebuildorder_cmd, '--no-reverse-deps' unless $reversedeps;
    @pactree = uniq @pactree;
    push @archrebuildorder_cmd, @pactree;

    my @ordered;
    if ( $opt{buildorder} ) {
        run( [@archrebuildorder_cmd], \undef,
            $self->outh( \@ordered, split => qr'\s' ) );
    }

    my $out;
    my @pkgtree = scalar @ordered ? @ordered : @pactree;
    $out = $base ? $self->pkgbase( \@pkgtree, dest => $out ) : \@pkgtree;
    @$out
}

method $run (%opt) {

    $self->pkgtree( \@in, %opt );
}

method cli : common ($argv = \@ARGV, %opt) {
    my $self    = $class->new( argv => $argv, %opt );
    my @pkgtree = $self->$run;

    BS::Common::dmsg( \@pkgtree );

    say "safsfd"
}

package main;

pkgtree->cli( \@ARGV )
